const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// นำ Auth Routes ของคุณมาใช้
const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authRoutes);

// นำ Concert Routes ของเพื่อนมาใช้
const concertRoutes = require('./routes/concertRoutes');
app.use('/api', concertRoutes);

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});