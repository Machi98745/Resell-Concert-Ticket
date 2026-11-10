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
const PAYMENT_TIMEOUT_MINUTES = 15;

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

// Middleware แบบ Optional (ถ้าส่ง Token มาจะถอดรหัสให้ ถ้าไม่ส่งก็ผ่านไปเช็ก body ต่อ)
const optionalVerifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token) {
    try {
      req.user = jwt.verify(token, JWT_KEY);
    } catch (_) {
      // ignore invalid optional token
    }
  }
  next();
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
    if (rows[0].is_active === 0) {
      return res.status(403).json({ message: 'Account disabled: Your account has been suspended.' });
    }
    res.status(200).json({ message: 'Token is valid', user: rows[0] });
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// รีเซ็ตรหัสผ่านด้วย Email และเบอร์โทรศัพท์ (รองรับ AuthController.resetPassword ของ Frontend)
app.post('/api/auth/reset-password', async (req, res) => {
  const { email, phone, new_password } = req.body;
  if (!email || !phone || !new_password) {
    return res.status(400).json({ message: 'Please provide email, phone, and new_password' });
  }

  try {
    const [users] = await db.query(
      'SELECT user_id FROM users WHERE email = ? AND phone = ?',
      [email.trim(), phone.trim()]
    );
    if (users.length === 0) {
      return res.status(404).json({ message: 'No matching account found for this email and phone number' });
    }

    const password_hash = await argon2.hash(new_password);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [
      password_hash,
      users[0].user_id
    ]);

    res.status(200).json({ message: 'Password reset successfully' });
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
app.use('/api/resell', optionalVerifyToken, resellRoutes);
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

// ============================================================================
// MODULE 5: PAYMENT (15-Min Timeout + Delivery/Meetup + Ownership Transfer)
// ============================================================================

// 1. สร้างรายการชำระเงิน (ล็อกเวลาจ่ายเงิน 15 นาที + เลือกจัดส่งหรือนัดรับ)
app.post('/api/payments/checkout', verifyToken, async (req, res) => {
  const { listing_id, payment_method, delivery_method, shipping_info } = req.body;
  const buyer_id = req.user.user_id;

  if (!listing_id || !payment_method) {
    return res.status(400).json({ message: 'listing_id and payment_method are required' });
  }

  const finalDeliveryMethod = delivery_method || 'delivery';
  if (finalDeliveryMethod !== 'delivery' && finalDeliveryMethod !== 'meetup') {
    return res.status(400).json({ message: 'Invalid delivery_method (must be delivery or meetup)' });
  }

  if (!shipping_info || shipping_info.trim() === '') {
    return res.status(400).json({
      message: finalDeliveryMethod === 'meetup'
        ? 'Please specify the location and time for ticket pickup (shipping_info).'
        : 'Please fill in the address for ticket delivery (shipping_info).'
    });
  }

  try {
    // 1. เช็กว่าตั๋วมือสองใบนี้ยังว่างอยู่ไหม
    const [listings] = await db.query(
      "SELECT * FROM resell_listings WHERE listing_id = ? AND status = 'available'",
      [listing_id]
    );
    if (listings.length === 0) {
      return res.status(404).json({ message: 'Resell listing not found or already sold' });
    }

    const listing = listings[0];

    // 2. [Sprint 3 Business Logic] ห้ามผู้ขายกดซื้อตั๋วที่ตัวเองลงขาย
    if (listing.seller_id === buyer_id) {
      return res.status(400).json({ message: 'You cannot purchase a ticket that you are listing for resale' });
    }

    const amount = listing.resell_price;

    // 3. บันทึกรายการรอชำระเงิน พร้อมกำหนดเวลาหมดอายุ 15 นาที
    const [result] = await db.query(
      `INSERT INTO payments (listing_id, buyer_id, amount, payment_method, delivery_method, shipping_info, status, expires_at)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
      [listing_id, buyer_id, amount, payment_method, finalDeliveryMethod, shipping_info.trim(), PAYMENT_TIMEOUT_MINUTES]
    );

    const [newPayment] = await db.query(
      'SELECT payment_id, listing_id, amount, delivery_method, shipping_info, status, expires_at FROM payments WHERE payment_id = ?',
      [result.insertId]
    );

    res.status(201).json({
      message: `Payment created successfully. Please complete the payment within ${PAYMENT_TIMEOUT_MINUTES} minutes.`,
      payment: newPayment[0]
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// 2. ยืนยันการชำระเงิน (เช็กว่าเกิน 15 นาทีหรือยัง + โอนสิทธิ์ตั๋วให้ผู้ซื้อ)
app.post('/api/payments/:id/confirm', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    const [payments] = await db.query('SELECT * FROM payments WHERE payment_id = ?', [id]);
    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    const payment = payments[0];

    // 1. [Sprint 3 Business Logic] ตรวจสอบว่าผู้กดยืนยันคือผู้ซื้อตัวจริง
    if (payment.buyer_id !== req.user.user_id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'You are not the owner of this payment and cannot confirm it' });
    }

    // 2. [Sprint 3 Business Logic] ตรวจสอบว่ารายการชำระเงินเสร็จสมบูรณ์ไปแล้วหรือยัง
    if (payment.status === 'completed') {
      return res.status(400).json({ message: 'This payment has already been confirmed' });
    }

    // 3. ตรวจสอบว่าเวลาปัจจุบัน (NOW) เลยเวลา expires_at ไปหรือยัง
    const [timeCheck] = await db.query(
      'SELECT (NOW() > expires_at) AS is_expired FROM payments WHERE payment_id = ?',
      [id]
    );

    if (timeCheck[0].is_expired) {
      await db.query("UPDATE payments SET status = 'expired' WHERE payment_id = ?", [id]);
      return res.status(400).json({
        message: `Payment expired (exceeded the payment time of ${PAYMENT_TIMEOUT_MINUTES} minutes. Please create a new request)`
      });
    }

    // 4. [Sprint 3 Business Logic] ตรวจสอบว่าประกาศขายใบนี้ยังเป็น 'available' อยู่หรือไม่
    const [listings] = await db.query(
      "SELECT status, ticket_id FROM resell_listings WHERE listing_id = ? AND status = 'available'",
      [payment.listing_id]
    );
    if (listings.length === 0) {
      return res.status(400).json({ message: 'This ticket has already been sold to another buyer' });
    }

    // 5. อัปเดตสถานะจ่ายเงินสำเร็จ + เปลี่ยนตั๋วเป็น sold + โอนตั๋วให้ผู้ซื้อ
    await db.query("UPDATE payments SET status = 'completed' WHERE payment_id = ?", [id]);
    await db.query("UPDATE resell_listings SET status = 'sold' WHERE listing_id = ?", [payment.listing_id]);
    await db.query(
      'UPDATE tickets SET user_id = ? WHERE ticket_id = ?',
      [payment.buyer_id, listings[0].ticket_id]
    );

    res.json({ message: 'Payment successful and ticket ownership transferred to the buyer.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});