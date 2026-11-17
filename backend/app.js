const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const concertRoutes = require('./routes/concertRoutes');
const resellRoutes = require('./routes/resellRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const resellController = require('./controllers/resellController');
const { verifyToken } = require('./middlewares/authMiddleware');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(
  '/uploads',
  express.static(path.join(__dirname, 'uploads'))
);
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// เปิดโฟลเดอร์เก็บรูปภาพโปสเตอร์คอนเสิร์ต
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/concerts', concertRoutes);
app.use('/api/resell', resellRoutes);
app.use('/api/payments', paymentRoutes);


// ============================================================================
// ROOT HEALTH CHECK
// ============================================================================
app.get('/', (req, res) => {
  res.send('Concert Resell Ticket API is running...');
});

// ==========================================
// 2. CONCERT MODULE (ดึงผ่าน Route อย่างเดียว)
// ==========================================
app.use('/api', concertRoutes);

module.exports = app;

// ==========================================
// START SERVER
// ==========================================
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});

