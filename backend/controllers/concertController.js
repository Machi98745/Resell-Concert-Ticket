const ConcertModel = require('../models/concertModel');

// ดึงคอนเสิร์ตทั้งหมด
exports.getAllConcerts = async (req, res) => {
  try {
    const { search } = req.query;
    const concerts = await ConcertModel.getAll(search);
    res.status(200).json(concerts);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// ดึงคอนเสิร์ตตาม ID
exports.getConcertById = async (req, res) => {
  try {
    const { id } = req.params;
    const concerts = await ConcertModel.getById(id);

    if (concerts.length === 0) {
      return res.status(404).json({ message: 'Concert not found' });
    }
    res.status(200).json(concerts[0]);
  } catch (err) {
    res.status(500).json({ message: 'Database Error', error: err.message });
  }
};