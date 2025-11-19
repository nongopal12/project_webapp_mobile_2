const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const path = require("path");
const moment = require("moment");
const con = require("../config/db");

const app = express();

/* ================== Middlewares ================== */
// รองรับเรียกจากมือถือ/Emulator และ body JSON
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/* ================== Static assets สำหรับรูปห้อง ================== */
// ตัวอย่าง: backend/assets/Meeting-RoomA.jpg
app.use("/assets", express.static(path.join(__dirname, "../assets")));

/* ================== Health check ================== */
app.get("/", (req, res) => {
  res.send("Server is running and connected to MySQL ✅");
});

/* ================== Password hash utility (ชั่วคราว) ==================
   ใช้สร้าง bcrypt hash เพื่ออัปเดตรหัสผ่านใน DB ด้วยมือ
   เสร็จงานแล้ว 'แนะนำให้ลบออก' เพื่อความปลอดภัย
*/
app.get("/password/:password", (req, res) => {
  const password = req.params.password;
  bcrypt.hash(password, 10, (err, hash) => {
    if (err) return res.status(500).send("Password Hashing Error");
    res.status(200).send(hash);
  });
});

/* ================== Debug: ดู DB ที่แอปกำลังเขียนจริง ==================
   เปิดในเบราว์เซอร์: http://localhost:3000/__debug/users
   จะเห็น current_db และ 10 ผู้ใช้ล่าสุด
*/
app.get("/__debug/users", (req, res) => {
  con.query(
    "SELECT DATABASE() AS current_db, id, username, user_email FROM `user` ORDER BY id DESC LIMIT 10",
    (err, rows) => {
      if (err) return res.status(500).json({ err });
      res.json(rows);
    }
  );
});

/* ================== REGISTER ================== */
app.post("/api/register", async (req, res) => {
  const { email, username, password } = req.body || {};

  if (!email || !username || !password) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  // ตรวจ username ซ้ำ
  con.query(
    "SELECT 1 FROM `user` WHERE username = ?",
    [username],
    async (err, rows) => {
      if (err) return res.status(500).json({ message: "DB error" });
      if (rows.length > 0) {
        return res.status(400).json({ message: "Username already exists" });
      }

      try {
        const hashed = await bcrypt.hash(password, 10);
        con.query(
          "INSERT INTO `user` (username, password, role, user_email) VALUES (?, ?, 3, ?)",
          [username, hashed, email],
          (err2, result) => {
            if (err2) {
              console.error("❌ Register failed:", err2);
              return res.status(500).json({ message: "Register failed" });
            }
            console.log("✅ Register success:", {
              insertId: result.insertId,
              username,
              email,
            });
            return res.json({
              message: "Register success",
              insertId: result.insertId,
            });
          }
        );
      } catch (e) {
        console.error("❌ Hashing error:", e);
        return res.status(500).json({ message: "Hashing error" });
      }
    }
  );
});

/* ================== LOGIN ================== */
app.post("/api/login", (req, res) => {
  const { username, password } = req.body || {};

  if (!username || !password) {
    return res.status(400).json({ message: "Missing username or password" });
  }

  con.query(
    "SELECT * FROM `user` WHERE username = ?",
    [username],
    async (err, rows) => {
      if (err) return res.status(500).json({ message: "DB error" });
      if (rows.length === 0) {
        return res.status(401).json({ message: "Invalid username or password" });
      }

      const user = rows[0];

      // ตรวจว่าค่าใน DB เป็น hash ไหม (bcrypt ขึ้นต้นด้วย $2)
      const isHashed =
        typeof user.password === "string" && user.password.startsWith("$2");
      let ok = false;

      try {
        ok = isHashed
          ? await bcrypt.compare(password, user.password)
          : password === user.password; // รองรับบัญชีเก่า (plaintext) ชั่วคราว
      } catch (e) {
        console.error("❌ bcrypt compare error:", e);
        return res.status(500).json({ message: "Error checking password" });
      }

      if (!ok) {
        return res.status(401).json({ message: "Invalid username or password" });
      }

      // map role → ชื่อ
      let roleName = "user"; // 3=user
      if (user.role == 1) roleName = "approver";
      else if (user.role == 2) roleName = "staff";

      console.log(`✅ Login success: ${username} (${roleName})`);
      return res.json({
        message: "Login success",
        id: user.id,
        role: roleName,
        username: user.username,
        email: user.user_email,
      });
    }
  );
});

////////////////////////////////////////////////// USER from BOOK //////////////////////////////////////////////////
// ================== GET all rooms (reset by day + auto close by time) ==================
app.get("/api/rooms", (req, res) => {
  const today = moment().format("YYYY-MM-DD");

  // STEP 1: ถ้าเปลี่ยนวัน -> รีเซ็ตทุกห้องให้เป็น Free ยกเว้น Disabled (4)
  const resetSql = `
    UPDATE booking
    SET
      room_date = ?,
      room_8AM  = CASE WHEN room_8AM  = 4 THEN 4 ELSE 1 END,
      room_10AM = CASE WHEN room_10AM = 4 THEN 4 ELSE 1 END,
      room_1PM  = CASE WHEN room_1PM  = 4 THEN 4 ELSE 1 END,
      room_3PM  = CASE WHEN room_3PM  = 4 THEN 4 ELSE 1 END
    WHERE DATE(room_date) != ? OR room_date IS NULL;
  `;

  con.query(resetSql, [today, today], (errReset) => {
    if (errReset) {
      console.error("⚠️ Error resetting rooms for new day:", errReset);
      // ยังไปต่อได้
    }

    // STEP 2: Auto-close slot ตามเวลา (ใช้ค่า 5 = หมดเวลาจองแล้ว)
    const autoCloseSql = `
      UPDATE booking
      SET
        -- 8.00 - 10.00 หมดเมื่อ >= 10:00
        room_8AM  = IF(TIME(NOW()) >= '10:00:00' AND room_8AM  = 1, 5, room_8AM),

        -- 10.00 - 12.00 หมดเมื่อ >= 12:00
        room_10AM = IF(TIME(NOW()) >= '12:00:00' AND room_10AM = 1, 5, room_10AM),

        -- 13.00 - 15.00 หมดเมื่อ >= 15:00
        room_1PM  = IF(TIME(NOW()) >= '15:00:00' AND room_1PM  = 1, 5, room_1PM),

        -- 15.00 - 17.00 หมดเมื่อ >= 17:00
        room_3PM  = IF(TIME(NOW()) >= '17:00:00' AND room_3PM  = 1, 5, room_3PM)
      WHERE DATE(room_date) = CURDATE();
    `;

    con.query(autoCloseSql, (errAuto) => {
      if (errAuto) {
        console.error("⚠️ Error auto closing slots:", errAuto);
      }

      // STEP 3: ดึงข้อมูลห้องหลังจากอัปเดตแล้วส่งให้ Flutter
      const selectSql = "SELECT * FROM booking WHERE DATE(room_date) = ?";
      con.query(selectSql, [today], (errSelect, results) => {
        if (errSelect) {
          console.error("❌ Error fetching rooms:", errSelect);
          return res.status(500).json({ message: "Database error" });
        }
        res.json(results);
      });
    });
  });
});


// ================== POST book a room ==================
app.post("/api/book", (req, res) => {
  const { user_id, room_id, time_slot, reason } = req.body || {};

  if (!user_id || !room_id || !time_slot || !reason) {
    return res.status(400).json({ message: "Missing booking data" });
  }

  // Convert slot number → column name
  const timeSlotMap = {
    1: "room_8AM",
    2: "room_10AM",
    3: "room_1PM",
    4: "room_3PM",
  };
  const column = timeSlotMap[time_slot];
  if (!column) {
    return res.status(400).json({ message: "Invalid time slot" });
  }

  // 🧠 Step 1: Check if the user already has a booking today
  const today = moment().format("YYYY-MM-DD");
  const checkUserSql = `
    SELECT COUNT(*) AS total
    FROM booking_history
    WHERE user_id = ? AND DATE(room_date) = ?
  `;
  con.query(checkUserSql, [user_id, today], (err, rows) => {
    if (err) {
      console.error("❌ Error checking user bookings:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (rows[0].total > 0) {
      // User already booked today
      return res
        .status(400)
        .json(
          "You already booked a room today. Only one booking per day is allowed."
        );
    }

    // 🧠 Step 2: Check if this room/time slot is available
    con.query(
      `SELECT ${column} FROM booking WHERE room_id = ?`,
      [room_id],
      (err2, rows2) => {
        if (err2) {
          console.error("❌ Error checking slot:", err2);
          return res.status(500).json({ message: "Database error" });
        }

        if (!rows2.length) {
          return res.status(404).json({ message: "Room not found" });
        }

        const status = rows2[0][column];
        if (status !== 1) {
          return res.status(400).json({ message: "Time slot not available" });
        }

        // 🧠 Step 3: Mark slot as pending
        con.query(
          `UPDATE booking SET ${column} = 2, room_date = NOW() WHERE room_id = ?`,
          [room_id],
          (err3) => {
            if (err3) {
              console.error("❌ Error updating slot:", err3);
              return res.status(500).json({ message: "Update failed" });
            }

            // 🧠 Step 4: Record booking history
            const insertSql = `
              INSERT INTO booking_history 
              (user_id, room_number, room_date, room_time, reason, status, approver_by)
                VALUES 
              (?, ?, NOW(), ?, ?, '1', 0)
                `;
            con.query(
              insertSql,
              [user_id, room_id, time_slot, reason],
              (err4) => {
                if (err4) {
                  console.error("❌ Error inserting history:", err4);
                  return res.status(500).json({ message: "Insert failed" });
                }

                console.log(
                  `✅ Booking created by user ${user_id} for room ${room_id}`
                );
                return res.json({
                  message: "Booking request submitted successfully",
                });
              }
            );
          }
        );
      }
    );
  });
});

////////////////////////////////////////////////// USER from jack //////////////////////////////////////////////////

/* ================== USER STATUS ================== */
app.get("/api/user/status/:uid", (req, res) => {
  const uid = req.params.uid;
  const sql = `
    SELECT bh.id, b.room_number, b.room_location, bh.room_date, bh.room_time, bh.reason, bh.status
    FROM booking_history bh
    JOIN booking b ON bh.room_number = b.room_id
    WHERE bh.user_id = ?
    ORDER BY bh.room_date DESC
  `;
  con.query(sql, [uid], (err, result) => {
    if (err) {
      console.error("❌ Error fetching status:", err.message);
      return res.status(500).send("Database server error");
    }
    res.json(result);
  });
});

/* ================== USER CHECK STATUS (Pending only) ================== */
app.get("/api/user/checkstatus/:uid", (req, res) => {
  const uid = req.params.uid;
  const sql = `
    SELECT 
      bh.id,
      b.room_number,
      b.room_location,
      bh.room_date,
      bh.room_time,
      bh.reason,
      bh.status
    FROM booking_history bh
    JOIN booking b ON bh.room_number = b.room_id
    WHERE bh.user_id = ? AND bh.status = '1'
    ORDER BY bh.room_date DESC
  `;
  con.query(sql, [uid], (err, result) => {
    if (err) {
      console.error("❌ Error fetching pending status:", err.message);
      return res.status(500).send("Database error while fetching pending");
    }
    res.json(result);
  });
});

/* ================== USER HISTORY (Approved & Rejected only) ================== */
app.get("/api/user/history/:uid", (req, res) => {
  const uid = req.params.uid;
  const sql = `
    SELECT 
      bh.id,
      b.room_number,
      b.room_location,
      bh.room_date,
      bh.room_time,
      bh.reason,
      bh.status,
      u.username AS booked_by,
      a.username AS approver_name,
      bh.approver_comment              -- ✅ เพิ่มตรงนี้
    FROM booking_history bh
    JOIN booking b ON bh.room_number = b.room_id
    JOIN \`user\` u ON bh.user_id = u.id
    LEFT JOIN \`user\` a ON bh.approver_by = a.id
    WHERE bh.user_id = ? AND bh.status IN ('2', '3')
    ORDER BY bh.room_date DESC
  `;
  con.query(sql, [uid], (err, result) => {
    if (err) {
      console.error("❌ Error fetching history:", err.message);
      return res.status(500).send("Database error while fetching history");
    }
    res.json(result);
  });
});



////////////////////////////////////////////////// Staff from toon //////////////////////////////////////////////////
// ==================== API dashboard staff (เวอร์ชันตามเวลา + รีเซ็ตวันใหม่) =======================
app.get("/api/staff/dashboard", (req, res) => {
  const today = moment().format("YYYY-MM-DD");

  // 1) รีเซ็ตวันใหม่:
  //    - ถ้า room_date != วันนี้ → อัปเดต room_date = วันนี้
  //    - slot ที่เป็น 1,2,3,5 ให้กลับเป็น 1 (Available)
  //    - slot ที่เป็น 4 (Disabled โดย staff) ยังเป็น 4 เหมือนเดิม
  const resetSql = `
    UPDATE booking
    SET 
      room_date = ?,
      room_8AM = CASE WHEN room_8AM IN (1,2,3,5) THEN 1 ELSE room_8AM END,
      room_10AM = CASE WHEN room_10AM IN (1,2,3,5) THEN 1 ELSE room_10AM END,
      room_1PM = CASE WHEN room_1PM IN (1,2,3,5) THEN 1 ELSE room_1PM END,
      room_3PM = CASE WHEN room_3PM IN (1,2,3,5) THEN 1 ELSE room_3PM END
    WHERE DATE(room_date) <> ?
  `;

  con.query(resetSql, [today, today], (err) => {
    if (err) {
      console.error("⚠️ Error reset day in dashboard:", err);
      return res.status(500).json({ message: "Database error (reset day)" });
    }

    // 2) ทำให้ slot ที่ "หมดเวลา" กลายเป็น 5 (Expired) ตามเวลาปัจจุบัน
    //    - หลัง 10:00 → หมดช่วง 8–10
    //    - หลัง 12:00 → หมดช่วง 10–12
    //    - หลัง 15:00 → หมดช่วง 13–15
    //    - หลัง 17:00 → หมดช่วง 15–17
    const expireSql = `
      UPDATE booking
      SET
        room_8AM = IF(TIME(NOW()) >= '10:00:00' AND room_8AM NOT IN (4,5), 5, room_8AM),
        room_10AM = IF(TIME(NOW()) >= '12:00:00' AND room_10AM NOT IN (4,5), 5, room_10AM),
        room_1PM = IF(TIME(NOW()) >= '15:00:00' AND room_1PM NOT IN (4,5), 5, room_1PM),
        room_3PM = IF(TIME(NOW()) >= '17:00:00' AND room_3PM NOT IN (4,5), 5, room_3PM)
      WHERE DATE(room_date) = ?
    `;

    con.query(expireSql, [today], (err2) => {
      if (err2) {
        console.error("⚠️ Error expire slots in dashboard:", err2);
        return res.status(500).json({ message: "Database error (expire slots)" });
      }

      // 3) ดึงค่าไปโชว์ใน Dashboard
      const countSql = `
        SELECT 
          -- 1 = Available
          SUM(
            (room_8AM = 1) +
            (room_10AM = 1) +
            (room_1PM = 1) +
            (room_3PM = 1)
          ) AS enable_count,

          -- 2 = Pending
          SUM(
            (room_8AM = 2) +
            (room_10AM = 2) +
            (room_1PM = 2) +
            (room_3PM = 2)
          ) AS pending_count,

          -- 3 = Reserved
          SUM(
            (room_8AM = 3) +
            (room_10AM = 3) +
            (room_1PM = 3) +
            (room_3PM = 3)
          ) AS reserved_count,

          -- 4 = Disabled (จริง ๆ) + 5 = Expired (หมดเวลา)
          SUM(
            (room_8AM IN (4,5)) +
            (room_10AM IN (4,5)) +
            (room_1PM IN (4,5)) +
            (room_3PM IN (4,5))
          ) AS disabled_count
        FROM booking
        WHERE DATE(room_date) = ?
      `;

      con.query(countSql, [today], (err3, result) => {
        if (err3) {
          console.error("DB error (count dashboard):", err3);
          return res
            .status(500)
            .json({ message: "Database error (count dashboard)" });
        }
        res.json(result[0]);
      });
    });
  });
});
// ✅ PROFILE BY USER ID (ใช้สำหรับ Staff Dashboard)
app.get("/api/profile/by-id/:uid", (req, res) => {
  const uid = req.params.uid;

  const sql = `
    SELECT 
      u.id AS user_id,
      CASE 
        WHEN u.role = 1 THEN 'Approver'
        WHEN u.role = 2 THEN 'Staff'
        WHEN u.role = 3 THEN 'User'
        ELSE 'Unknown'
      END AS role_name
    FROM user AS u
    WHERE u.id = ?
  `;

  con.query(sql, [uid], (err, results) => {
    if (err) {
      console.error("DB error /api/profile/by-id:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(results[0]);   // { user_id: 2, role_name: "Staff" }
  });
});


// ==================== API Get Data Room for staff ===================== //
app.get("/api/staff/rooms", (req, res) => {
  const sql = `
    SELECT 
      room_id AS id,
      room_number,
      room_location,
      room_capacity,
      room_img AS imagePath,
      CONCAT('Room ', room_location, '0', room_number) AS name,
      CONCAT(room_location, ' Floor') AS location,
      CASE
        WHEN room_8AM = 4 AND room_10AM = 4 AND room_1PM = 4 AND room_3PM = 4 THEN 'Disable'
        WHEN room_8AM = 3 OR room_10AM = 3 OR room_1PM = 3 OR room_3PM = 3 THEN 'Reserved'
        WHEN room_8AM = 2 OR room_10AM = 2 OR room_1PM = 2 OR room_3PM = 2 THEN 'Pending'
        ELSE 'Enable'
      END AS status
    FROM booking
    ORDER BY room_location ASC, room_number ASC;
  `;

  con.query(sql, (err, results) => {
    if (err) {
      console.error("DB error /api/staff/rooms:", err);
      return res.status(500).json({ message: "Database error" });
    }
    res.json(results);
  });
});


// ====================  Add Room Staff ===================== //
app.post("/api/staff/rooms", (req, res) => {
  const { room_number, room_location, room_capacity, room_img } = req.body;

  if (!room_number || !room_location || !room_capacity || !room_img) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  // 🔍 CHECK DUPLICATE: ห้องเลขเดียวกัน + ชั้นเดียวกัน ห้ามซ้ำ
  const sqlCheckDup = `
    SELECT * FROM booking
    WHERE room_number = ? AND room_location = ?
  `;

  con.query(sqlCheckDup, [room_number, room_location], (err, rows) => {
    if (err) return res.status(500).json({ message: "Database error" });

    if (rows.length > 0) {
      return res
        .status(400)
        .json({ message: "This room already exists on this floor." });
    }

    // ใช้ชื่อไฟล์รูปอย่างเดียว
    const imageName = room_img.split("/").pop();

    const sqlInsert = `
      INSERT INTO booking 
        (room_number_id, room_number, room_capacity, room_location, room_date, room_img,
         room_8AM, room_10AM, room_1PM, room_3PM)
      VALUES (?, ?, ?, ?, NOW(), ?, 1, 1, 1, 1)
    `;

    con.query(
      sqlInsert,
      [
        room_number,        // room_number_id (ใช้เหมือน room_id)
        room_number,        // room_number
        room_capacity,
        room_location,
        imageName
      ],
      (err) => {
        if (err) {
          console.error("DB error /api/staff/rooms (POST):", err);
          return res.status(500).json({ message: "Failed to create room" });
        }

        return res.status(201).json({
          message: "Room created successfully",
        });
      }
    );
  });
});

// ====================  Edit Room Staff ===================== //
app.put("/api/staff/rooms/:id", (req, res) => {
  const { id } = req.params;
  const { room_number, room_capacity } = req.body;

  if (!room_number || !room_capacity) {
    return res.status(400).json({ message: "Missing fields" });
  }

  // 🔍 หาชั้นของห้องนี้ก่อน (เอา room_location เดิม)
  const sqlGetLocation = `
    SELECT room_location FROM booking WHERE room_id = ?
  `;

  con.query(sqlGetLocation, [id], (err, rows) => {
    if (err || rows.length === 0) {
      return res.status(404).json({ message: "Room not found" });
    }

    const room_location = rows[0].room_location;

    // 🔍 CHECK DUPLICATE: ห้ามใช้เลขห้องที่มีอยู่แล้วในชั้นเดียวกัน
    const sqlCheckDup = `
      SELECT * FROM booking 
      WHERE room_number = ? 
      AND room_location = ?
      AND room_id != ?
    `;

    con.query(sqlCheckDup, [room_number, room_location, id], (err2, dup) => {
      if (err2) return res.status(500).json({ message: "Database error" });

      if (dup.length > 0) {
        return res.status(400).json({
          message: "This room number already exists on this floor.",
        });
      }

      // ไม่มีซ้ำ → ทำการแก้ไข
      const sqlUpdate = `
        UPDATE booking 
        SET room_number = ?, 
            room_capacity = ?
        WHERE room_id = ?
      `;

      con.query(sqlUpdate, [room_number, room_capacity, id], (err3) => {
        if (err3)
          return res.status(500).json({ message: "Failed to update room" });

        return res.json({ message: "Room updated successfully" });
      });
    });
  });
});

// ==================== Disable Room Staff ===================== //
app.put("/api/staff/rooms/:id/status", (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // รับ "Enable" หรือ "Disable"

  let sql;

  if (status === "Disable") {
    // ถ้าสั่ง Disable: ตั้งค่าทุกช่องเป็น 4 (Disabled)
    sql = `
      UPDATE booking 
      SET room_8AM = 4, room_10AM = 4, room_1PM = 4, room_3PM = 4 
      WHERE room_id = ?
    `;
  } else if (status === "Enable") {
    // ถ้าสั่ง Enable: ตั้งค่าเฉพาะช่องที่เป็น 4 (Disabled) กลับเป็น 1 (Free)
    sql = `
      UPDATE booking 
      SET 
        room_8AM = IF(room_8AM = 4, 1, room_8AM),
        room_10AM = IF(room_10AM = 4, 1, room_10AM),
        room_1PM = IF(room_1PM = 4, 1, room_1PM),
        room_3PM = IF(room_3PM = 4, 1, room_3PM)
      WHERE room_id = ?
    `;
  } else {
    return res.status(400).json({ message: "Invalid status" });
  }

  con.query(sql, [id], (err, result) => {
    if (err) {
      console.error("DB error /api/staff/rooms/status (PUT):", err);
      return res.status(500).json({ message: "Failed to update status" });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Room not found" });
    }
    res.json({ message: `Room status updated to ${status}` });
  });
});

// ==================== API History staff (เวอร์ชันใหม่ มี image) ====================== //
app.get("/api/staff/history", (req, res) => {
  const sql = `
    SELECT 
      h.id,
      u.username AS name,
      CONCAT('Room ', b.room_location, '0', b.room_number) AS room,
      DATE_FORMAT(h.room_date, '%e %b %Y') AS date, 
      
      CASE h.room_time 
        WHEN 1 THEN '8:00 AM - 10:00 AM'
        WHEN 2 THEN '10:00 AM - 12:00 PM'
        WHEN 3 THEN '1:00 PM - 3:00 PM'
        WHEN 4 THEN '3:00 PM - 5:00 PM'
        ELSE 'Unknown' 
      END AS time,

      h.reason,

      CASE h.status
        WHEN '1' THEN 'Pending'
        WHEN '2' THEN 'Approved'
        WHEN '3' THEN 'Reject'
        ELSE 'Unknown'
      END AS status,

      b.room_img AS image,

      -- 👇 เพิ่มชื่อ Approver 
      a.username AS approver_name,

      -- 👇 เพิ่ม Comment ของ Approver
      h.approver_comment

    FROM booking_history AS h
    JOIN user AS u ON h.user_id = u.id
    JOIN booking AS b ON h.room_number = b.room_id
    LEFT JOIN user AS a ON h.approver_by = a.id   -- 👈 เพิ่ม join นี้
    ORDER BY h.room_date DESC, h.room_time DESC;
  `;

  con.query(sql, (err, results) => {
    if (err) {
      console.error("DB error /api/staff/history:", err);
      return res.status(500).json({ message: "Database error" });
    }
    res.json(results);
  });
});

// ====================  UPDATE STATUS Dashboard page (Can be use all role) ==================== //
app.put("/api/approver/booking/:id", (req, res) => {
  const { id } = req.params;
  const { status, approver_id, reject_reason } = req.body; 
  // status: "2" = approve, "3" = reject

  if (!["2", "3"].includes(status)) {
    return res.status(400).json({ message: "Invalid status value" });
  }

  const approverIdValue = approver_id || null;

  // ถ้า reject ให้เก็บข้อความ reject_reason, ถ้า approve ให้เป็น NULL
  const commentValue =
    status === "3" && reject_reason && reject_reason.trim() !== ""
      ? reject_reason.trim()
      : null;

  // 1) อัปเดต booking_history: status + approver_by + approver_comment
  const updateHistory = `
    UPDATE booking_history 
    SET status = ?, approver_by = ?, approver_comment = ? 
    WHERE id = ?
  `;

  con.query(
    updateHistory,
    [status, approverIdValue, commentValue, id],
    (err, result) => {
      if (err) {
        console.error("DB error /api/approver/booking (UPDATE history):", err);
        return res
          .status(500)
          .json({ message: "Failed to update booking history" });
      }

      // 2) ดึง room_number, room_time เพื่อไปอัปเดต booking table
      const getHistory =
        "SELECT room_number, room_time FROM booking_history WHERE id = ?";
      con.query(getHistory, [id], (err2, rows) => {
        if (err2 || rows.length === 0) {
          return res
            .status(404)
            .json({ message: "Booking history not found" });
        }

        const { room_number, room_time } = rows[0];

        let timeColumn = "";
        if (room_time === 1) timeColumn = "room_8AM";
        else if (room_time === 2) timeColumn = "room_10AM";
        else if (room_time === 3) timeColumn = "room_1PM";
        else if (room_time === 4) timeColumn = "room_3PM";

        const newStatus = status === "2" ? 3 : 1; // 3 = Reserved, 1 = Free

        const updateBooking =
          "UPDATE booking SET " + timeColumn + " = ? WHERE room_id = ?";
        con.query(updateBooking, [newStatus, room_number], (err3) => {
          if (err3) {
            console.error(
              "DB error /api/approver/booking (UPDATE booking):",
              err3
            );
            return res
              .status(500)
              .json({ message: "Failed to update booking table" });
          }

          res.json({
            message:
              status === "2"
                ? "Booking approved and room reserved"
                : "Booking rejected and room released",
          });
        });
      });
    }
  );
});

// ==================== API PROFILE CARD For staff/approver/user ========================== //
app.get("/api/profile/:username", (req, res) => {
  const { username } = req.params;

  const sql = `
    SELECT 
      u.id AS user_id,
      u.username,
      u.user_email,
      CASE 
        WHEN u.role = 1 THEN 'Approver'
        WHEN u.role = 2 THEN 'Staff'
        WHEN u.role = 3 THEN 'User'
        ELSE 'Unknown'
      END AS role_name
    FROM user AS u
    WHERE u.username = ?
  `;

  con.query(sql, [username], (err, results) => {
    if (err) {
      console.error("DB error /api/profile:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(results[0]);
  });
});

////////////////////////////////////////////////// Approver from J (เพิ่มมาจากไฟล์แรก) //////////////////////////////////////////////////

// ✅ API HISTORY FOR APPROVER (filter ตามวันที่ได้)
app.get("/api/history", (req, res) => {
  const { date } = req.query;
  console.log("📅 Filter date from Flutter:", date);

  const params = [];

  // ✅ เฉพาะ status 2 (Approved) และ 3 (Rejected)
  let sql = `
    SELECT 
      h.id,
      u.username AS booking_name,
      u.user_email,
      b.room_number AS room_number,
      DATE_FORMAT(h.room_date, '%Y-%m-%d') AS room_date,
      CASE 
        WHEN h.room_time = 1 THEN '08:00 - 10:00'
        WHEN h.room_time = 2 THEN '10:00 - 12:00'
        WHEN h.room_time = 3 THEN '13:00 - 15:00'
        WHEN h.room_time = 4 THEN '15:00 - 17:00'
        ELSE 'Unknown'
      END AS room_time,
      h.reason,
      h.status
    FROM booking_history h
    JOIN \`user\` u ON h.user_id = u.id
    JOIN booking b ON h.room_number = b.room_id
    WHERE h.status IN (2, 3)
  `;

  // ✅ ถ้ามีการส่ง date จาก Flutter ให้เพิ่มเงื่อนไขกรองวันที่
  if (date) {
    sql += ` AND DATE_FORMAT(h.room_date, '%Y-%m-%d') = ? `;
    params.push(date);
    console.log("🧠 SQL Filter Active:", sql, params);
  } else {
    console.log("📜 Showing all approved/rejected (no date filter)");
  }

  sql += " ORDER BY h.room_date DESC, h.room_time ASC";

  con.query(sql, params, (err, results) => {
    if (err) {
      console.error("❌ Error fetching history:", err);
      return res.status(500).json({ error: "Database error" });
    }

    // ✅ ปรับโครงสร้างผลลัพธ์ก่อนส่งกลับ
    const formatted = results.map((row) => ({
      id: row.id,
      name: row.booking_name,
      user_email: row.user_email,
      room_number: `Room ${row.room_number}`,
      room_date: row.room_date,
      time: row.room_time,
      reason: row.reason,
      status: row.status,
    }));

    res.json(formatted);
  });
});

/* ================== Start server ================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
