const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('../db_config');
const { JWT_KEY } = require('../middlewares/authMiddleware');

// 1. สมัครสมาชิก (POST /api/auth/register)
exports.register = async (req, res) => {
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
      userRole,
    ]);

    return res.status(201).json({
      message: 'User registration successful.',
      user_id: result.insertId,
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message: 'This username or email is already in use.',
      });
    }
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 2. เข้าสู่ระบบ (POST /api/auth/login)
exports.login = async (req, res) => {
  const { username, email, password } = req.body;
  const loginIdentifier = username || email;

  if (!loginIdentifier || !password) {
    return res.status(400).json({
      message: 'Please provide both username/email and password.',
    });
  }

  try {
    const [users] = await db.query(
      'SELECT * FROM users WHERE username = ? OR email = ?',
      [loginIdentifier, loginIdentifier]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const user = users[0];

    if (user.is_active === 0) {
      return res.status(403).json({
        message: 'This account has been suspended by Admin.',
      });
    }

    const isValid = await argon2.verify(user.password_hash, password);
    if (!isValid) {
      return res.status(401).json({ message: 'Incorrect password.' });
    }

    const token = jwt.sign(
      {
        user_id: user.user_id,
        username: user.username,
        role: user.role,
        is_verified: user.is_verified,
      },
      JWT_KEY,
      { expiresIn: '2h' }
    );

    return res.status(200).json({
      message: 'Login successful.',
      token,
      user: {
        user_id: user.user_id,
        username: user.username,
        full_name: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        is_verified: user.is_verified,
        is_active: user.is_active,
      },
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server Error', error: err.message });
  }
};

// 3. ดึงข้อมูลโปรไฟล์ตัวเอง (GET /api/auth/me)
exports.getMe = async (req, res) => {
  try {
    const [users] = await db.query(
      `SELECT user_id, username, email, full_name, phone, role, is_verified, is_active, created_at
       FROM users WHERE user_id = ?`,
      [req.user.user_id]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.status(200).json(users[0]);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 4. แก้ไขโปรไฟล์ (PUT /api/auth/profile)
exports.updateProfile = async (req, res) => {
  const { full_name, email, phone } = req.body;

  if (!full_name || !email) {
    return res.status(400).json({ message: 'full_name and email are required.' });
  }

  try {
    await db.query(
      'UPDATE users SET full_name = ?, email = ?, phone = ? WHERE user_id = ?',
      [full_name, email, phone || null, req.user.user_id]
    );

    const [updated] = await db.query(
      'SELECT user_id, username, email, full_name, phone, role, is_verified, is_active FROM users WHERE user_id = ?',
      [req.user.user_id]
    );

    return res.status(200).json({
      message: 'Profile updated successfully.',
      user: updated[0],
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        message: 'This email is already in use by another account.',
      });
    }
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 5. เปลี่ยนรหัสผ่าน (PUT /api/auth/change-password)
exports.changePassword = async (req, res) => {
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).json({
      message: 'Please provide both current_password and new_password.',
    });
  }

  try {
    const [users] = await db.query(
      'SELECT password_hash FROM users WHERE user_id = ?',
      [req.user.user_id]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const isValid = await argon2.verify(users[0].password_hash, current_password);
    if (!isValid) {
      return res.status(401).json({ message: 'Current password is incorrect.' });
    }

    const newHash = await argon2.hash(new_password);
    await db.query(
      'UPDATE users SET password_hash = ? WHERE user_id = ?',
      [newHash, req.user.user_id]
    );

    return res.status(200).json({ message: 'Password updated successfully.' });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};
