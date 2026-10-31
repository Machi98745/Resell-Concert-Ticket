const express = require('express');
const cors = require('cors');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('./db_config'); // ดึง connection pool มาใช้งาน

const JWT_KEY = 'thisisthesecretforjwt_concert_app'; // แนะนำให้เปลี่ยนรหัส Secret
const app = express();
app.use(cors());
app.use(express.json());

// ==========================================
// 1. API REGISTER (สมัครสมาชิก)
// ==========================================
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  // ตรวจสอบข้อมูลเบื้องต้น
  if (!username || !email || !password || !full_name) {
    return res.status(400).send('Please provide all the required information.');
  }

  try {
    // เข้ารหัส Password ด้วย Argon2id
    const password_hash = await argon2.hash(password);
    const userRole = role || 'customer'; // ถ้าไม่ส่ง role มา ให้เป็น customer

    const sql = `INSERT INTO users (username, email, password_hash, full_name, phone, role) 
                 VALUES (?, ?, ?, ?, ?, ?)`;

    db.query(sql, [username, email, password_hash, full_name, phone, userRole], (err, result) => {
      if (err) {
        console.error(err);
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(400).send('This username or email is already in use.');
        }
        return res.status(500).send('Database error');
      }
      res.status(201).json({ message: 'Registration successful', userId: result.insertId });
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Hashing error');
  }
});

// ==========================================
// 2. API LOGIN (เข้าสู่ระบบ)
// ==========================================
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).send('Please enter your username and password.');
  }

  const sql = "SELECT * FROM users WHERE username = ?";
  db.query(sql, [username], async (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Database error');
    }

    // เช็กว่าพบผู้ใช้หรือไม่
    if (result.length !== 1) {
      return res.status(401).send('Wrong username or password');
    }

    const user = result[0];

    // ตรวจสอบ Password Hash ด้วย Argon2
    try {
      const isMatch = await argon2.verify(user.password_hash, password);
      if (!isMatch) {
        return res.status(401).send('Wrong username or password');
      }

      // สร้าง JWT Token ฝัง user_id, username และ role
      const payload = { 
        user_id: user.user_id, 
        username: user.username, 
        role: user.role 
      };
      const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });

      res.json({
        message: 'Login successful',
        token: token,
        user: {
          user_id: user.user_id,
          username: user.username,
          full_name: user.full_name,
          role: user.role
        }
      });
    } catch (verifyErr) {
      console.error(verifyErr);
      res.status(500).send('Password verification error');
    }
  });
});

// ==========================================
// 3. AUTH MIDDLEWARE (ตัวเช็กสิทธิ์ JWT)
// ==========================================
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).send('Access Token Required');

  jwt.verify(token, JWT_KEY, (err, user) => {
    if (err) return res.status(403).send('Invalid or Expired Token');
    req.user = user;
    next();
  });
};

// ตัวอย่าง API ที่ต้องผ่านการตรวจสอบ JWT Token
app.get('/api/auth/me', authenticateToken, (req, res) => {
  res.json({ user: req.user });
});

// ==========================================
// START SERVER
// ==========================================
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});