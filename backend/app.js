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
// AUTH MIDDLEWARE
// ==========================================

// 1. ตรวจสอบ JWT Token ใน Header (Authorization: Bearer <token>)
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_KEY);
    req.user = decoded; // มี { user_id, username, role }
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token.' });
  }
};

// 2. ตรวจสอบสิทธิ์ตาม Role (customer, organizer, admin)
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Forbidden: You do not have permission to access this resource.' });
    }
    next();
  };
};

// ==========================================
// 1. AUTH MODULE
// ==========================================

// Register
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  if (!username || !email || !password || !full_name) {
    return res.status(400).send('Please provide all the required information.');
  }

  try {
    const password_hash = await argon2.hash(password);
    const userRole = role || 'customer';
    const sql = `INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?)`;

    const [result] = await db.query(sql, [username, email, password_hash, full_name, phone || null, userRole]);
    res.status(201).json({ message: 'Registration successful', userId: result.insertId });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).send('Username or Email is already in use');
    }
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).send('Please provide both Username and Password');
  }

  try {
    const sql = "SELECT * FROM users WHERE username = ?";
    const [result] = await db.query(sql, [username]);

    if (result.length !== 1) {
      return res.status(401).send('Invalid username or password');
    }

    const user = result[0];
    const isMatch = await argon2.verify(user.password_hash, password);
    if (!isMatch) {
      return res.status(401).send('Invalid username or password');
    }

    const token = jwt.sign(
      { user_id: user.user_id, username: user.username, role: user.role },
      JWT_KEY,
      { expiresIn: '1d' }
    );

    res.status(200).json({
      message: 'Login successful',
      token,
      user: { user_id: user.user_id, username: user.username, role: user.role }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// API สำหรับทดสอบ Auth Middleware & Role
app.get('/api/auth/me', verifyToken, (req, res) => {
  res.status(200).json({ message: 'Token is valid', user: req.user });
});

// ==========================================
// 2. CONCERT MODULE (ระบบคอนเสิร์ต)
// ==========================================

// ดึงคอนเสิร์ตทั้งหมด
app.get('/api/concerts', async (req, res) => {
  const { search } = req.query;
  let sql = "SELECT * FROM concerts";
  let params = [];

  if (search && search.trim() !== '') {
    sql += " WHERE title LIKE ? OR venue LIKE ?";
    const keyword = `%${search.trim()}%`;
    params = [keyword, keyword];
  }

  try {
    const [results] = await db.query(sql, params);
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ดึงรายละเอียดคอนเสิร์ตตาม ID
app.get('/api/concerts/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [results] = await db.query("SELECT * FROM concerts WHERE concert_id = ?", [id]);
    if (results.length === 0) return res.status(404).json({ message: 'Concert not found' });
    res.status(200).json(results[0]);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});