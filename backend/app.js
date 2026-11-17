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

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// เปิดโฟลเดอร์เก็บรูปภาพโปสเตอร์คอนเสิร์ต
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ============================================================================
// MOUNT MODULES (แยกตาม Module ชัดเจนตามโครงสร้าง MVC)
// ============================================================================

// Module 1: Auth & Profile (/api/auth/*)
app.use('/api/auth', authRoutes);

// Module 2: Admin Management (/api/admin/*)
app.use('/api/admin', adminRoutes);

// Module 3: Concerts (/api/concerts/*)
app.use('/api/concerts', concertRoutes);

// Module 4: Resell Tickets & User Tickets (/api/resell/* และ /api/user/my-tickets)
app.use('/api/resell', resellRoutes);
app.get('/api/user/my-tickets', verifyToken, resellController.getMyTickets);

// Module 5: Payment & Orders (/api/payments/*)
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