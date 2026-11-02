const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const concertRoutes = require('./routes/concertRoutes');
app.use('/api', concertRoutes);

app.get('/', (req, res) => {
  res.send('Tixxa Resell Concert Backend Running');
});

app.listen(PORT, () => {
  console.log(`Backend server running on http://localhost:${PORT}`);
});