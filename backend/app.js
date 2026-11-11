const express = require('express');
const cors = require('cors');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const db = require('./db_config');

// นำเข้า Routes ระบบคอนเสิร์ต
const concertRoutes = require('./routes/concertRoutes');

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
    return res.status(400).send('Please provide all the required information.');
  }

  try {
    const password_hash = await argon2.hash(password);
    const userRole = role || 'customer';
    const sql = `INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?)`;

    db.query(sql, [username, email, password_hash, full_name, phone, userRole], (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') return res.status(400).send('Username or Email is already in use');
        return res.status(500).send('Database error');
      }
      res.status(201).json({ message: 'Registration successful', userId: result.insertId });
    });
  } catch (err) {
    res.status(500).send('Hashing error');
  }
});

// Login
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).send('Please provide both Username and Password');

  const sql = "SELECT * FROM users WHERE username = ?";
  db.query(sql, [username], async (err, result) => {
    if (err || result.length !== 1) return res.status(401).send('Invalid username or password');

    const user = result[0];
    try {
      const isMatch = await argon2.verify(user.password_hash, password);
      if (!isMatch) return res.status(401).send('Invalid username or password');

      const token = jwt.sign({ user_id: user.user_id, username: user.username, role: user.role }, JWT_KEY, { expiresIn: '1d' });
      res.json({ message: 'Login successful', token, user: { user_id: user.user_id, username: user.username, role: user.role } });
    } catch (err) {
      res.status(500).send('Password verification error');
    }
  });
});
module.exports = app;
// ==========================================
// 2. CONCERT MODULE (ดึงผ่าน Route อย่างเดียว)
// ==========================================
app.use('/api', concertRoutes);

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});