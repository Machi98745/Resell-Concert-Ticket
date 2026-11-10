const express = require('express');
const cors = require('cors');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('./db_config');

const resellRoutes = require('./routes/resellRoutes');
const resellController = require('./controllers/resellController');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_KEY = process.env.JWT_SECRET || 'thisisthesecretforjwt_concert_app';

app.use(cors());
app.use(express.json());

// ==========================================
// AUTH MIDDLEWARE (ตรวจสอบ JWT Token & Role)
// ==========================================
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_KEY);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token.' });
  }
};

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
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  if (!username || !email || !password || !full_name) {
    return res.status(400).json({ message: 'Please provide all the required information.' });
  }

  try {
    const password_hash = await argon2.hash(password);
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
app.get('/api/concerts', async (req, res) => {
  const { search, category } = req.query;
  let sql = 'SELECT * FROM concerts WHERE 1=1';
  const params = [];

  if (search && search.trim() !== '') {
    sql += ' AND (title LIKE ? OR venue LIKE ? OR artist LIKE ?)';
    const keyword = `%${search.trim()}%`;
    params.push(keyword, keyword, keyword);
  }

  if (category && category !== 'All') {
    sql += ' AND category = ?';
    params.push(category);
  }

  sql += ' ORDER BY show_datetime ASC';

  try {
    const [results] = await db.query(sql, params);
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

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
// 4. RESELL MODULE (เชื่อมงานของ 6731501049)
// ==========================================
app.use('/api/resell', resellRoutes);
app.get('/api/user/my-tickets', verifyToken, resellController.getMyTickets);

// API สำหรับเสก/เพิ่มตั๋วเข้าตัว User (ไว้ใช้ตอนเทสระบบ)
app.post('/api/user/add-ticket', async (req, res) => {
  const { user_id, concert_id, ticket_code, zone_name, seat_number, original_price } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO tickets (user_id, concert_id, ticket_code, zone_name, seat_number, original_price) VALUES (?, ?, ?, ?, ?, ?)',
      [user_id || 1, concert_id || 1, ticket_code || `TKT-${Date.now()}`, zone_name || 'VIP A1', seat_number || 'A1-99', original_price || 4500]
    );
    res.status(201).json({ message: 'Ticket added successfully', ticket_id: result.insertId });
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ==========================================
// 5. PAYMENT MODULE (Timeout 15 นาที + ที่อยู่จัดส่ง / นัดรับบัตร)
// ==========================================

// 5.1 สร้างรายการรอชำระเงิน (เลือกจัดส่ง/นัดรับ + ตั้งเวลา 15 นาที)
app.post('/api/payments/checkout', verifyToken, async (req, res) => {
  const buyer_id = req.user.user_id;
  const { listing_id, payment_method, delivery_method, shipping_info } = req.body;

  if (!listing_id || !payment_method || !delivery_method || !shipping_info) {
    return res.status(400).json({
      message: 'กรุณาระบุข้อมูลให้ครบ: listing_id, payment_method, delivery_method (delivery/meetup), และ shipping_info (ที่อยู่หรือจุดนัดรับ)'
    });
  }

  try {
    const [listings] = await db.query(
      "SELECT * FROM resell_listings WHERE listing_id = ? AND status = 'available'",
      [listing_id]
    );
    if (listings.length === 0) {
      return res.status(404).json({ message: 'Ticket is no longer available' });
    }

    const listing = listings[0];

    const sql = `
      INSERT INTO payments (listing_id, buyer_id, amount, payment_method, delivery_method, shipping_info, status, expires_at)
      VALUES (?, ?, ?, ?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL 15 MINUTE))
    `;
    const [result] = await db.query(sql, [
      listing_id,
      buyer_id,
      listing.resell_price,
      payment_method,
      delivery_method, // 'delivery' หรือ 'meetup'
      shipping_info    // ที่อยู่จัดส่ง หรือ จุดนัดรับ
    ]);

    res.status(201).json({
      message: 'สร้างรายการสั่งซื้อสำเร็จ กรุณาชำระเงินภายใน 15 นาที',
      payment_id: result.insertId,
      delivery_method,
      shipping_info,
      timeout_minutes: 15
    });
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// 5.2 ยืนยันการชำระเงิน (เช็กว่าเกิน 15 นาทีหรือยัง)
app.post('/api/payments/:id/confirm', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    const [payments] = await db.query(
      'SELECT *, (NOW() > expires_at) AS is_expired FROM payments WHERE payment_id = ?',
      [id]
    );

    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment record not found' });
    }

    const payment = payments[0];

    if (payment.is_expired || payment.status === 'expired') {
      await db.query("UPDATE payments SET status = 'expired' WHERE payment_id = ?", [id]);
      return res.status(400).json({
        message: 'Payment timeout: หมดเวลาชำระเงิน (เกิน 15 นาที) กรุณาทำรายการใหม่'
      });
    }

    await db.query("UPDATE payments SET status = 'completed', paid_at = NOW() WHERE payment_id = ?", [id]);
    await db.query("UPDATE resell_listings SET status = 'sold' WHERE listing_id = ?", [payment.listing_id]);

    // ย้ายเจ้าของตั๋วไปเป็นของคนซื้อ
    await db.query(
      `UPDATE tickets t
       JOIN resell_listings rl ON rl.ticket_id = t.ticket_id
       SET t.user_id = ?
       WHERE rl.listing_id = ?`,
      [payment.buyer_id, payment.listing_id]
    );

    res.status(200).json({
      message: 'Payment completed successfully!',
      payment_id: Number(id),
      delivery_method: payment.delivery_method,
      shipping_info: payment.shipping_info,
      status: 'completed'
    });
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