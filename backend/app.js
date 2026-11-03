const express = require('express');
const cors = require('cors');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('./db_config');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_KEY = process.env.JWT_SECRET || 'thisisthesecretforjwt_concert_app';

app.use(cors());
app.use(express.json());

// ==========================================
// 1. AUTH MODULE (ระบบสมาชิก)
// ==========================================

// Register
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  if (!username || !email || !password || !full_name) {
    return res.status(400).send('กรุณากรอกข้อมูลให้ครบถ้วน');
  }

  try {
    const password_hash = await argon2.hash(password);
    const userRole = role || 'customer';
    const sql = `INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?)`;

    db.query(sql, [username, email, password_hash, full_name, phone, userRole], (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') return res.status(400).send('Username หรือ Email ถูกใช้งานแล้ว');
        return res.status(500).send('Database error');
      }
      res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', userId: result.insertId });
    });
  } catch (err) {
    res.status(500).send('Hashing error');
  }
});

// Login
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).send('กรุณากรอก Username และ Password');

  const sql = "SELECT * FROM users WHERE username = ?";
  db.query(sql, [username], async (err, result) => {
    if (err || result.length !== 1) return res.status(401).send('Wrong username or password');

    const user = result[0];
    try {
      const isMatch = await argon2.verify(user.password_hash, password);
      if (!isMatch) return res.status(401).send('Wrong username or password');

      const token = jwt.sign({ user_id: user.user_id, username: user.username, role: user.role }, JWT_KEY, { expiresIn: '1d' });
      res.json({ message: 'เข้าสู่ระบบสำเร็จ', token, user: { user_id: user.user_id, username: user.username, role: user.role } });
    } catch (err) {
      res.status(500).send('Password verification error');
    }
  });
});

// ==========================================
// 2. CONCERT MODULE (ระบบคอนเสิร์ต)
// ==========================================

// ดึงคอนเสิร์ตทั้งหมด
app.get('/api/concerts', (req, res) => {
  const { search } = req.query;
  let sql = "SELECT * FROM concerts";
  let params = [];

  if (search && search.trim() !== '') {
    sql += " WHERE name LIKE ? OR venue LIKE ?";
    const keyword = `%${search.trim()}%`;
    params = [keyword, keyword];
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database Error', error: err.message });
    res.status(200).json(results);
  });
});

// ดึงรายละเอียดคอนเสิร์ตตาม ID
app.get('/api/concerts/:id', (req, res) => {
  const { id } = req.params;
  const sql = "SELECT * FROM concerts WHERE concert_id = ?";

  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ message: 'Database Error', error: err.message });
    if (results.length === 0) return res.status(404).json({ message: 'Concert not found' });
    res.status(200).json(results[0]);
  });
});

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});