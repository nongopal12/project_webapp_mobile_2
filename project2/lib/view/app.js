const express = require("express");
const path = require("path");
const cors = require("cors");
const session = require("express-session");
const multer = require("multer");
const bcrypt = require("bcrypt");
const db = require("../config/db");
const app = express();


// หน้าเริ่มต้น
app.get("/", (req, res) => {
  res.send("Server is running and connected to MySQL ✅");
});

// ====== START SERVER ======
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});