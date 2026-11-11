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
const COMMISSION_RATE = 0.02;
const PARCEL_SHIPPING_FEE = 50;

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

// ============================================================================
// MODULE 1: AUTH & PROFILE (ระบบสมาชิก, แก้ไขโปรไฟล์, เปลี่ยนรหัสผ่าน)
// ============================================================================
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
      username.trim(),
      email.trim(),
      password_hash,
      full_name.trim(),
      phone ? phone.trim() : null,
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
    const [result] = await db.query('SELECT * FROM users WHERE username = ?', [username.trim()]);

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
        email: user.email,
        full_name: user.full_name,
        phone: user.phone,
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

// แก้ไขโปรไฟล์ (รองรับหน้า profile.dart -> Edit Profile)
app.put('/api/auth/profile', verifyToken, async (req, res) => {
  const { full_name, email, phone } = req.body;
  if (!full_name || !email) {
    return res.status(400).json({ message: 'full_name and email are required' });
  }

  try {
    await db.query(
      'UPDATE users SET full_name = ?, email = ?, phone = ? WHERE user_id = ?',
      [full_name.trim(), email.trim(), phone ? phone.trim() : null, req.user.user_id]
    );
    const [updated] = await db.query(
      'SELECT user_id, username, email, full_name, phone, role, is_verified, is_active FROM users WHERE user_id = ?',
      [req.user.user_id]
    );
    res.status(200).json({ message: 'Profile updated successfully', user: updated[0] });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ message: 'Email is already in use' });
    }
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// เปลี่ยนรหัสผ่านขณะล็อกอินอยู่ (รองรับหน้า profile.dart -> Settings -> Change Password)
app.post('/api/auth/change-password', verifyToken, async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ message: 'Please provide current_password and new_password' });
  }

  try {
    const [users] = await db.query('SELECT password_hash FROM users WHERE user_id = ?', [req.user.user_id]);
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await argon2.verify(users[0].password_hash, current_password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    const newHash = await argon2.hash(new_password);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [newHash, req.user.user_id]);
    res.status(200).json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// รีเซ็ตรหัสผ่านกรณีลืมรหัสผ่าน (รองรับหน้า login.dart -> Forgot Password)
app.post('/api/auth/reset-password', async (req, res) => {
  const { email, phone, new_password } = req.body;
  if (!email || !phone || !new_password) {
    return res.status(400).json({ message: 'Please provide email, phone, and new_password' });
  }

  try {
    const [users] = await db.query(
      'SELECT user_id, username FROM users WHERE email = ? AND phone = ?',
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

    res.status(200).json({ message: 'Password reset successfully', username: users[0].username });
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
});

// ============================================================================
// MODULE 2: ADMIN MODULE (รองรับหน้า admin_page.dart ครบทุกปุ่ม)
// ============================================================================
app.get('/api/admin/users', verifyToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const [users] = await db.query(`
      SELECT 
        u.user_id,
        u.username,
        u.email,
        u.full_name,
        u.phone,
        u.role,
        u.is_verified,
        u.is_active,
        u.created_at,
        (SELECT COUNT(*) FROM resell_listings rl WHERE rl.seller_id = u.user_id AND rl.status = 'sold') AS ticketsSold,
        (SELECT COUNT(*) FROM payments p WHERE p.buyer_id = u.user_id AND p.status = 'completed') AS ticketsBought
      FROM users u
      ORDER BY u.user_id ASC
    `);
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

app.delete('/api/admin/users/:id', verifyToken, authorizeRoles('admin'), async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await db.query('DELETE FROM users WHERE user_id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'User account deleted successfully', user_id: Number(id) });
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

// ============================================================================
// MODULE 3: CONCERT MODULE (รองรับหน้า homepage.dart และ detail.dart)
// ============================================================================
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

// ============================================================================
// MODULE 4: RESELL & MY TICKETS MODULE (รองรับ sell_page.dart และ MyResellingPage)
// ============================================================================
app.use('/api/resell', optionalVerifyToken, resellRoutes);
app.get('/api/user/my-tickets', verifyToken, resellController.getMyTickets);

app.get('/api/user/my-resell-listings', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT 
         rl.listing_id,
         rl.ticket_id,
         rl.resell_price,
         rl.status,
         rl.created_at,
         t.ticket_code,
         t.zone_name,
         t.seat_number,
         t.original_price,
         c.concert_id,
         c.title AS concert_title,
         c.venue,
         c.show_datetime
       FROM resell_listings rl
       JOIN tickets t ON rl.ticket_id = t.ticket_id
       JOIN concerts c ON t.concert_id = c.concert_id
       WHERE rl.seller_id = ?
       ORDER BY rl.created_at DESC`,
      [req.user.user_id]
    );
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
});

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
// MODULE 5: PAYMENT & ORDER HISTORY (รองรับ payment_page.dart & historypage.dart)
// ============================================================================
app.post('/api/payments/checkout', verifyToken, async (req, res) => {
  const { listing_id, payment_method, delivery_method, shipping_info } = req.body;
  const buyer_id = req.user.user_id;

  if (!listing_id || !payment_method) {
    return res.status(400).json({ message: 'listing_id and payment_method are required' });
  }

  const allowedDelivery = ['delivery', 'meetup', 'Parcel Shipping', 'Digital Transfer'];
  const finalDeliveryMethod = delivery_method || 'delivery';
  if (!allowedDelivery.includes(finalDeliveryMethod)) {
    return res.status(400).json({
      message: 'Invalid delivery_method (must be delivery, meetup, Parcel Shipping, or Digital Transfer)'
    });
  }

  if (!shipping_info || shipping_info.trim() === '') {
    return res.status(400).json({
      message: finalDeliveryMethod === 'meetup'
        ? 'Please specify the location and time for ticket pickup (shipping_info).'
        : 'Please fill in the address or email for ticket delivery (shipping_info).'
    });
  }

  try {
    const [listings] = await db.query(
      "SELECT * FROM resell_listings WHERE listing_id = ? AND status = 'available'",
      [listing_id]
    );
    if (listings.length === 0) {
      return res.status(404).json({ message: 'Resell listing not found or already sold' });
    }

    const listing = listings[0];

    if (listing.seller_id === buyer_id) {
      return res.status(400).json({ message: 'You cannot purchase a ticket that you are listing for resale' });
    }

    const ticketPrice = Number(listing.resell_price);
    const commissionFee = Math.round(ticketPrice * COMMISSION_RATE);
    const shippingFee = (finalDeliveryMethod === 'Parcel Shipping' || finalDeliveryMethod === 'delivery') ? PARCEL_SHIPPING_FEE : 0;
    const totalAmount = ticketPrice;

    const [result] = await db.query(
      `INSERT INTO payments (listing_id, buyer_id, amount, payment_method, delivery_method, shipping_info, status, expires_at)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
      [listing_id, buyer_id, totalAmount, payment_method, finalDeliveryMethod, shipping_info.trim(), PAYMENT_TIMEOUT_MINUTES]
    );

    const [newPayment] = await db.query(
      'SELECT * FROM payments WHERE payment_id = ?',
      [result.insertId]
    );

    res.status(201).json({
      message: `Payment created successfully. Please complete the payment within ${PAYMENT_TIMEOUT_MINUTES} minutes.`,
      payment: {
        ...newPayment[0],
        commission_fee: commissionFee,
        shipping_fee: shippingFee,
        total_buyer_payment: ticketPrice + commissionFee + shippingFee
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

app.post('/api/payments/:id/confirm', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    const [payments] = await db.query('SELECT * FROM payments WHERE payment_id = ?', [id]);
    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    const payment = payments[0];

    if (payment.buyer_id !== req.user.user_id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'You are not the owner of this payment and cannot confirm it' });
    }

    // ตรวจสอบว่าสถานะต้องเป็น 'pending' เท่านั้น (ป้องกันรายการที่จ่ายไปแล้ว ยกเลิกไปแล้ว หรือหมดอายุไปแล้ว)
    if (payment.status !== 'pending') {
      return res.status(400).json({ message: `Cannot confirm payment with status: ${payment.status}` });
    }

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

    const [listings] = await db.query(
      "SELECT status, ticket_id FROM resell_listings WHERE listing_id = ? AND status = 'available'",
      [payment.listing_id]
    );
    if (listings.length === 0) {
      return res.status(400).json({ message: 'This ticket has already been sold to another buyer' });
    }

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

app.post('/api/payments/:id/cancel', verifyToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [payments] = await db.query('SELECT * FROM payments WHERE payment_id = ?', [id]);
    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    if (payments[0].buyer_id !== req.user.user_id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }
    if (payments[0].status !== 'pending') {
      return res.status(400).json({ message: 'Only pending orders can be cancelled' });
    }

    await db.query("UPDATE payments SET status = 'failed' WHERE payment_id = ?", [id]);
    res.status(200).json({ message: 'Order cancelled successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

app.get('/api/payments/my-orders', verifyToken, async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT 
         p.*,
         rl.resell_price,
         t.ticket_code,
         t.zone_name,
         t.seat_number,
         c.title AS concert_title,
         c.artist,
         c.venue,
         c.show_datetime
       FROM payments p
       JOIN resell_listings rl ON p.listing_id = rl.listing_id
       JOIN tickets t ON rl.ticket_id = t.ticket_id
       JOIN concerts c ON t.concert_id = c.concert_id
       WHERE p.buyer_id = ?
       ORDER BY p.paid_at DESC`,
      [req.user.user_id]
    );
    res.status(200).json(orders);
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