const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const bcrypt = require("bcryptjs"); // ใช้สำหรับ hash และตรวจรหัสผ่าน
const con = require("./config/db"); // เชื่อมกับฐานข้อมูล

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ================================================================
// ==================== REGISTER API ================================
// ================================================================
app.post("/api/register", async (req, res) => {
  const { email, username, password } = req.body;

  // ตรวจว่ากรอกครบหรือไม่
  if (!email || !username || !password)
    return res.status(400).json({ message: "Missing required fields" });

  // ตรวจว่ามี username ซ้ำไหม
  const checkSQL = "SELECT * FROM user WHERE username = ?";
  con.query(checkSQL, [username], async (err, result) => {
    if (err) return res.status(500).json({ message: "DB error" });
    if (result.length > 0)
      return res.status(400).json({ message: "Username already exists" });

    try {
      // เข้ารหัสรหัสผ่านก่อนเก็บ
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // ✅ แก้ตำแหน่ง parameter ให้ถูก
      const insertSQL =
        "INSERT INTO user (username, password, role, user_email) VALUES (?, ?, ?, ?)";
      con.query(insertSQL, [username, hashedPassword, 3, email], (err) => {
        if (err) {
          console.error("❌ Register failed:", err);
          return res.status(500).json({ message: "Register failed" });
        }
        console.log("✅ Register success:", username);
        res.json({ message: "Register success" });
      });
    } catch (error) {
      console.error("❌ Hashing error:", error);
      res.status(500).json({ message: "Hashing error" });
    }
  });
});

// ================================================================
// ==================== LOGIN API ==================================
// ================================================================
app.post("/api/login", (req, res) => {
  const { username, password } = req.body;

  if (!username || !password)
    return res.status(400).json({ message: "Missing username or password" });

  const sql = "SELECT * FROM user WHERE username = ?";
  con.query(sql, [username], async (err, results) => {
    if (err) return res.status(500).json({ message: "DB error" });
    if (results.length === 0)
      return res.status(401).json({ message: "Invalid username or password" });

    const user = results[0];

    // ✅ ตรวจสอบรหัสผ่าน — รองรับทั้ง plain text และ hashed
    let isMatch = false;
    try {
      if (user.password === password) {
        // ถ้าเป็น plain text (เช่น user เก่าใน DB)
        isMatch = true;
      } else {
        // ถ้าเป็น hash
        isMatch = await bcrypt.compare(password, user.password);
      }
    } catch (compareErr) {
      console.error("❌ bcrypt compare error:", compareErr);
      return res.status(500).json({ message: "Error checking password" });
    }

    if (!isMatch)
      return res.status(401).json({ message: "Invalid username or password" });

    // แปลง role เป็นชื่อ
    let roleName = "user";
    if (user.role == 1) roleName = "approver";
    else if (user.role == 2) roleName = "staff";

    console.log(`✅ Login success: ${username} (${roleName})`);
    res.json({
      message: "Login success",
      role: roleName,
      username: user.username,
      email: user.user_email,
    });
  });
});

// ================================================================
// ==================== Role Staff (เพิ่ม API ภายหลังได้) ==========
// ================================================================

//--------------- START SERVER ------------------//
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
