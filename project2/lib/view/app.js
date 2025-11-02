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



////////////////////////////////////////////////// Staff from opal //////////////////////////////////////////////////



////////////////////////////////////////////////// Approver from X //////////////////////////////////////////////////



////////////////////////////////////////////////// Approver from J //////////////////////////////////////////////////







/* ================== Start server ================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
