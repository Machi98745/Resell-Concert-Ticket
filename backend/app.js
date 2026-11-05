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
// AUTH MIDDLEWARE (ตรวจสอบ JWT Token & Role)
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
    req.user = decoded; // เก็บ { user_id, username, role, is_verified }
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token.' });
  }
};

// 2. ตรวจสอบสิทธิ์ตาม Role ('customer', 'admin')
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Forbidden: You do not have permission to access this resource.' });
    }
    next();
  };
};

// ==========================================
// 1. AUTH MODULE (ระบบสมาชิก)
// ==========================================

// สมัครสมาชิก (Register)
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  if (!username || !email || !password || !full_name) {
    return res.status(400).json({ message: 'Please provide all the required information.' });
  }

  try {
    const password_hash = await argon2.hash(password);
    // กำหนดค่าเริ่มต้นเป็น customer เสมอ (ยกเว้นส่ง role: 'admin' มาตอนเทส)
    const userRole = role === 'admin' ? 'admin' : 'customer';

    const sql = `
      INSERT INTO users (username, email, password_hash, full_name, phone, role, is_verified, is_active)
      VALUES (?, ?, ?, ?, ?, ?, 0, 1)
    `;

    const [result] = await db.query(sql, [
      username,
      email,
      password_hash,
      full_name,
      phone || null,
      userRole
    ]);

    res.status(201).json({
      message: 'Registration successful',
      userId: result.insertId
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ message: 'Username or Email is already in use' });
    }
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// เข้าสู่ระบบ (Login)
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ message: 'Please provide both Username and Password' });
  }

  try {
    const sql = 'SELECT * FROM users WHERE username = ?';
    const [result] = await db.query(sql, [username]);

    if (result.length !== 1) {
      return res.status(401).json({ message: 'Invalid username or password' });
    }

    const user = result[0];

    // เช็กว่าบัญชีถูก Admin ปิดการใช้งาน (is_active = 0) หรือไม่
    if (user.is_active === 0) {
      return res.status(403).json({
        message: 'Account disabled: Your account has been suspended by an administrator.'
      });
    }

    const isMatch = await argon2.verify(user.password_hash, password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid username or password' });
    }

    const token = jwt.sign(
      {
        user_id: user.user_id,
        username: user.username,
        role: user.role,
        is_verified: user.is_verified
      },
      JWT_KEY,
      { expiresIn: '1d' }
    );

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        user_id: user.user_id,
        username: user.username,
        full_name: user.full_name,
        role: user.role,
        is_verified: user.is_verified,
        is_active: user.is_active
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ตรวจสอบข้อมูลตัวเองจาก Token (ใช้เทส Middleware)
app.get('/api/auth/me', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT user_id, username, email, full_name, phone, role, is_verified, is_active, created_at FROM users WHERE user_id = ?',
      [req.user.user_id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'Token is valid', user: rows[0] });
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// ==========================================
// 2. ADMIN MODULE (จัดการผู้ใช้ & ยืนยันตัวตนผู้ขาย)
// ==========================================

// ดึงรายชื่อผู้ใช้ทั้งหมด (เฉพาะ Admin)
app.get('/api/admin/users', verifyToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT user_id, username, email, full_name, phone, role, is_verified, is_active, created_at FROM users ORDER BY user_id ASC'
    );
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// เปิด-ปิดการใช้งานบัญชี User (is_active: 1 = เปิด, 0 = ปิด/ระงับ)
app.patch('/api/admin/users/:id/status', verifyToken, authorizeRoles('admin'), async (req, res) => {
  const { id } = req.params;
  const { is_active } = req.body;

  if (is_active !== 0 && is_active !== 1) {
    return res.status(400).json({ message: 'Please provide is_active as 1 (active) or 0 (disabled)' });
  }

  try {
    const [result] = await db.query('UPDATE users SET is_active = ? WHERE user_id = ?', [is_active, id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({
      message: is_active === 1 ? 'User account enabled' : 'User account disabled',
      user_id: Number(id),
      is_active
    });
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ยืนยันตัวตนผู้ขายว่าเป็นคนจริง (is_verified: 1 = คนจริง, 0 = ยังไม่ยืนยัน)
app.patch('/api/admin/users/:id/verify', verifyToken, authorizeRoles('admin'), async (req, res) => {
  const { id } = req.params;
  const { is_verified } = req.body;

  if (is_verified !== 0 && is_verified !== 1) {
    return res.status(400).json({ message: 'Please provide is_verified as 1 (verified) or 0 (unverified)' });
  }

  try {
    const [result] = await db.query('UPDATE users SET is_verified = ? WHERE user_id = ?', [is_verified, id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({
      message: is_verified === 1 ? 'Seller verified as real person' : 'Seller verification removed',
      user_id: Number(id),
      is_verified
    });
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ==========================================
// 3. CONCERT MODULE (ระบบคอนเสิร์ต)
// ==========================================

// ดึงคอนเสิร์ตทั้งหมด (พร้อมค้นหาจาก title หรือ venue)
app.get('/api/concerts', async (req, res) => {
  const { search } = req.query;
  let sql = 'SELECT * FROM concerts';
  let params = [];

  if (search && search.trim() !== '') {
    sql += ' WHERE title LIKE ? OR venue LIKE ?';
    const keyword = `%${search.trim()}%`;
    params = [keyword, keyword];
  }

  sql += ' ORDER BY show_datetime ASC';

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
    const [results] = await db.query('SELECT * FROM concerts WHERE concert_id = ?', [id]);
    if (results.length === 0) {
      return res.status(404).json({ message: 'Concert not found' });
    }
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