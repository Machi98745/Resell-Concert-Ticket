const ConcertModel = require('../models/concertModel');

// 1. ดึงคอนเสิร์ตทั้งหมด รองรับทั้ง search และ category (GET /api/concerts)
exports.getAllConcerts = async (req, res) => {
  try {
    const { search, category } = req.query;
    const concerts = await ConcertModel.getAll(search, category);
    return res.status(200).json(concerts);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 2. ดึงรายละเอียดคอนเสิร์ตตาม ID (GET /api/concerts/:id)
exports.getConcertById = async (req, res) => {
  try {
    const { id } = req.params;
    const concerts = await ConcertModel.getById(id);

    if (concerts.length === 0) {
      return res.status(404).json({ message: 'Concert not found.' });
    }
    return res.status(200).json(concerts[0]);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};
