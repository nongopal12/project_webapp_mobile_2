const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");          
const con = require("../config/db");         
const app = express();

/* ================== Middlewares ================== */
// รองรับเรียกจากมือถือ/Emulator และ body JSON
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
  con.query("SELECT 1 FROM `user` WHERE username = ?", [username], async (err, rows) => {
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
          console.log("✅ Register success:", { insertId: result.insertId, username, email });
          return res.json({ message: "Register success", insertId: result.insertId });
        }
      );
    } catch (e) {
      console.error("❌ Hashing error:", e);
      return res.status(500).json({ message: "Hashing error" });
    }
  });
});

/* ================== LOGIN ================== */
app.post("/api/login", (req, res) => {
  const { username, password } = req.body || {};

  if (!username || !password) {
    return res.status(400).json({ message: "Missing username or password" });
  }

  con.query("SELECT * FROM `user` WHERE username = ?", [username], async (err, rows) => {
    if (err) return res.status(500).json({ message: "DB error" });
    if (rows.length === 0) {
      return res.status(401).json({ message: "Invalid username or password" });
    }

    const user = rows[0];

    // ตรวจว่าค่าใน DB เป็น hash ไหม (bcrypt ขึ้นต้นด้วย $2)
    const isHashed = typeof user.password === "string" && user.password.startsWith("$2");
    let ok = false;

    try {
      ok = isHashed ? await bcrypt.compare(password, user.password)
                    : (password === user.password); // รองรับบัญชีเก่า (plaintext) ชั่วคราว
    } catch (e) {
      console.error("❌ bcrypt compare error:", e);
      return res.status(500).json({ message: "Error checking password" });
    }

    if (!ok) {
      return res.status(401).json({ message: "Invalid username or password" });
    }

    // map role → ชื่อ
    let roleName = "user";        // 3=user
    if (user.role == 1) roleName = "approver";
    else if (user.role == 2) roleName = "staff";

    console.log(`✅ Login success: ${username} (${roleName})`);
    return res.json({
      message: "Login success",
      role: roleName,
      username: user.username,
      email: user.user_email,
    });
  });
});




////////////////////////////////////////////////// user from BOOK //////////////////////////////////////////////////



////////////////////////////////////////////////// USER from jack //////////////////////////////////////////////////



////////////////////////////////////////////////// Staff from toon //////////////////////////////////////////////////

// ==================== API dashborad staff =======================

app.get("/api/staff/dashboard", (req, res) => {
  const sql = `
    SELECT 
      SUM(CASE WHEN room_8AM = 1 THEN 1 ELSE 0 END +
          CASE WHEN room_10AM = 1 THEN 1 ELSE 0 END +
          CASE WHEN room_1PM = 1 THEN 1 ELSE 0 END +
          CASE WHEN room_3PM = 1 THEN 1 ELSE 0 END) AS enable_count,
      SUM(CASE WHEN room_8AM = 2 THEN 1 ELSE 0 END +
          CASE WHEN room_10AM = 2 THEN 1 ELSE 0 END +
          CASE WHEN room_1PM = 2 THEN 1 ELSE 0 END +
          CASE WHEN room_3PM = 2 THEN 1 ELSE 0 END) AS pending_count,
      SUM(CASE WHEN room_8AM = 3 THEN 1 ELSE 0 END +
          CASE WHEN room_10AM = 3 THEN 1 ELSE 0 END +
          CASE WHEN room_1PM = 3 THEN 1 ELSE 0 END +
          CASE WHEN room_3PM = 3 THEN 1 ELSE 0 END) AS reserved_count,
      SUM(CASE WHEN room_8AM = 4 THEN 1 ELSE 0 END +
          CASE WHEN room_10AM = 4 THEN 1 ELSE 0 END +
          CASE WHEN room_1PM = 4 THEN 1 ELSE 0 END +
          CASE WHEN room_3PM = 4 THEN 1 ELSE 0 END) AS disabled_count
    FROM booking;
  `;
  con.query(sql, (err, result) => {
    if (err) {
      console.error("DB error:", err);
      return res.status(500).json({ message: "Database error" });
    }
    res.json(result[0]); // ส่งผลลัพธ์กลับเป็น object เดียว
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
      
      -- สร้างชื่อห้องจาก ชั้น และ เลขห้อง (เช่น Room 101, Room 203)
      CONCAT('Room ', room_location, '0', room_number) AS name,
      
      -- สร้าง Location (เช่น 1st Floor, 2nd Floor)
      CONCAT(room_location, ' Floor') AS location,
      
      -- สร้าง Status รวมของห้อง
      CASE
        WHEN room_8AM = 4 AND room_10AM = 4 AND room_1PM = 4 AND room_3PM = 4 THEN 'Disable'
        WHEN room_8AM = 3 OR room_10AM = 3 OR room_1PM = 3 OR room_3PM = 3 THEN 'Reserved'
        WHEN room_8AM = 2 OR room_10AM = 2 OR room_1PM = 2 OR room_3PM = 2 THEN 'Pending'
        ELSE 'Enable'
      END AS status
      
    FROM booking
    ORDER BY room_id ASC;
  `;

  con.query(sql, (err, results) => {
    if (err) {
      console.error("DB error /api/staff/rooms (GET):", err);
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

  // แยกเอาเฉพาะชื่อไฟล์ภาพ
  const imageName = room_img.split('/').pop();
  const sqlInsert = `
    INSERT INTO booking 
      (room_number, room_location, room_capacity, room_img, room_date, room_8AM, room_10AM, room_1PM, room_3PM) 
    VALUES 
      (?, ?, ?, ?, NOW(), 1, 1, 1, 1);
  `;

  con.query(
    sqlInsert,
    [room_number, room_location, room_capacity, imageName],
    (err, result) => {
      if (err) {
        console.error("DB error /api/staff/rooms (POST):", err);
        return res.status(500).json({ message: "Failed to create room" });
      }

      const newRoomId = result.insertId;
      const sqlUpdateId = "UPDATE booking SET room_number_id = ? WHERE room_id = ?";
      
      con.query(sqlUpdateId, [newRoomId, newRoomId], () => {
         res.status(201).json({ message: "Room created successfully" });
      });
    }
  );
});


// ====================  Edit Room Staff ===================== //

app.put("/api/staff/rooms/:id", (req, res) => {
  const { id } = req.params;
  const { room_number, room_capacity } = req.body; 

  if (!room_number || !room_capacity) { 
    return res.status(400).json({ message: "Missing required fields: room_number, room_capacity" });
  }

  const sql = `
    UPDATE booking 
    SET 
      room_number = ?, 
      room_capacity = ?
    WHERE room_id = ?
  `; 
  con.query(sql, [room_number, room_capacity, id], (err, result) => { 
    if (err) {
      console.error("DB error /api/staff/rooms (PUT):", err);
      return res.status(500).json({ message: "Failed to update room" });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Room not found" });
    }
    res.json({ message: "Room updated successfully" });
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


// ==================== API History staff ====================== //
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
      END AS status
    FROM 
      booking_history AS h
    JOIN 
      user AS u ON h.user_id = u.id
    JOIN 
      booking AS b ON h.room_number = b.room_id
    ORDER BY 
      h.room_date DESC;
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
  const { status } = req.body; // 2=approve, 3=reject

  if (!["2", "3"].includes(status))
    return res.status(400).json({ message: "Invalid status value" });

  // อัปเดตตาราง booking_history
  const updateHistory = "UPDATE booking_history SET status = ? WHERE id = ?";
  con.query(updateHistory, [status, id], (err, result) => {
    if (err) {
      console.error("DB error /api/approver/booking (UPDATE history):", err);
      return res.status(500).json({ message: "Failed to update booking history" });
    }

    // ดึงข้อมูล booking_history ที่เพิ่งอัปเดต เพื่อเอาค่า room_number และ room_time ไปอัปเดตใน booking
    const getHistory =
      "SELECT room_number, room_time FROM booking_history WHERE id = ?";
    con.query(getHistory, [id], (err, rows) => {
      if (err || rows.length === 0)
        return res.status(404).json({ message: "Booking history not found" });

      const { room_number, room_time } = rows[0];

      // กำหนดชื่อคอลัมน์ใน booking ที่จะอัปเดต เช่น room_8AM / room_10AM / room_1PM / room_3PM
      let timeColumn = "";
      if (room_time === 1) timeColumn = "room_8AM";
      else if (room_time === 2) timeColumn = "room_10AM";
      else if (room_time === 3) timeColumn = "room_1PM";
      else if (room_time === 4) timeColumn = "room_3PM";

      // ถ้า Approve ให้ค่าคอลัมน์นั้น = 3 (Reserved)
      // ถ้า Reject ให้ค่าคอลัมน์นั้น = 1 (Free)
      const newStatus = status === "2" ? 3 : 1;

      const updateBooking = `UPDATE booking SET ${timeColumn} = ? WHERE room_id = ?`;
      con.query(updateBooking, [newStatus, room_number], (err2) => {
        if (err2) {
          console.error("DB error /api/approver/booking (UPDATE booking):", err2);
          return res.status(500).json({ message: "Failed to update booking table" });
        }
        res.json({
          message:
            status === "2"
              ? "Booking approved and room reserved"
              : "Booking rejected and room released",
        });
      });
    });
  });
});

// ==================== API PROFILE CARD For staff ========================== //
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




////////////////////////////////////////////////// Staff from opal //////////////////////////////////////////////////



////////////////////////////////////////////////// Approver from X //////////////////////////////////////////////////



////////////////////////////////////////////////// Approver from J //////////////////////////////////////////////////







/* ================== Start server ================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
