const db = require('../db_config');

// 1. ดึงคอนเสิร์ตทั้งหมด (GET /api/concerts)
exports.getAllConcerts = async (req, res) => {
  const { search } = req.query;
  let sql = 'SELECT * FROM concerts';
  let params = [];

  if (search && search.trim() !== '') {
    sql += ' WHERE title LIKE ? OR venue LIKE ?';
    const keyword = `%${search.trim()}%`;
    params = [keyword, keyword];
  }

  sql += ' ORDER BY show_datetime ASC';

  try {
    const [results] = await db.query(sql, params);
    return res.status(200).json(results);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 2. ดึงรายละเอียดคอนเสิร์ตตาม ID (GET /api/concerts/:id)
exports.getConcertById = async (req, res) => {
  const { id } = req.params;

  try {
    const [concerts] = await db.query('SELECT * FROM concerts WHERE concert_id = ?', [id]);
    if (concerts.length === 0) {
      return res.status(404).json({ message: 'Concert not found.' });
    }
    return res.status(200).json(concerts[0]);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};
