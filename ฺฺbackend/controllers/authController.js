const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('../db_config');

const JWT_KEY = process.env.JWT_SECRET || 'thisisthesecretforjwt_concert_app';

// 1. Register
exports.register = async (req, res) => {
  const { username, email, password, full_name, phone, role } = req.body;

  if (!username || !email || !password || !full_name) {
    return res.status(400).send('กรุณากรอกข้อมูลให้ครบถ้วน');
  }

  try {
    const password_hash = await argon2.hash(password);
    const userRole = role || 'customer';

    const sql = `INSERT INTO users (username, email, password_hash, full_name, phone, role) 
                 VALUES (?, ?, ?, ?, ?, ?)`;

    db.query(sql, [username, email, password_hash, full_name, phone, userRole], (err, result) => {
      if (err) {
        console.error(err);
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(400).send('Username หรือ Email นี้ถูกใช้งานแล้ว');
        }
        return res.status(500).send('Database error');
      }
      res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', userId: result.insertId });
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Hashing error');
  }
};

// 2. Login
exports.login = (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).send('กรุณากรอก Username และ Password');
  }

  const sql = "SELECT * FROM users WHERE username = ?";
  db.query(sql, [username], async (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Database error');
    }

    if (result.length !== 1) {
      return res.status(401).send('Wrong username or password');
    }

    const user = result[0];

    try {
      const isMatch = await argon2.verify(user.password_hash, password);
      if (!isMatch) {
        return res.status(401).send('Wrong username or password');
      }

      const payload = { 
        user_id: user.user_id, 
        username: user.username, 
        role: user.role 
      };
      const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });

      res.json({
        message: 'เข้าสู่ระบบสำเร็จ',
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
};

// 3. Middleware ตรวจ JWT
exports.authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).send('Access Token Required');

  jwt.verify(token, JWT_KEY, (err, user) => {
    if (err) return res.status(403).send('Invalid or Expired Token');
    req.user = user;
    next();
  });
};