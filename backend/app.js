const resellRoutes = require('./routes/resellRoutes');
const resellController = require('./controllers/resellController');

app.use('/api/resell', resellRoutes);
app.get('/api/user/my-tickets', verifyToken, resellController.getMyTickets);