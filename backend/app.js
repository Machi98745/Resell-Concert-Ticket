
const express = require('express');
const cors = require('cors');

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

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/concerts', concertRoutes);
app.use('/api/resell', resellRoutes);
app.use('/api/payments', paymentRoutes);

app.get(
  '/api/user/my-tickets',
  verifyToken,
  resellController.getMyTickets
);

app.get('/', (req, res) => {
  res.send('Concert Resell Ticket API is running...');
});

app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});

module.exports = app;
