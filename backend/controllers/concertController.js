
const ConcertModel = require('../models/concertModel');

// GET /api/concerts
// ดึงรายการคอนเสิร์ตทั้งหมด
exports.getAllConcerts = async (req, res) => {
  try {
    const { search } = req.query;

    const concerts = await ConcertModel.getAll(search);

    return res.status(200).json(concerts);
  } catch (err) {
    console.error('Get all concerts error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message
    });
  }
};

// GET /api/concerts/:id
// ดึงรายละเอียดคอนเสิร์ตตาม ID
exports.getConcertById = async (req, res) => {
  try {
    const { id } = req.params;

    // ตรวจสอบว่า ID เป็นตัวเลขหรือไม่
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({
        message: 'Invalid concert ID'
      });
    }

    const concert = await ConcertModel.getById(id);

    if (!concert) {
      return res.status(404).json({
        message: 'Concert not found'
      });
    }

    return res.status(200).json(concert);
  } catch (err) {
    console.error('Get concert by ID error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message
    });
  }
};
