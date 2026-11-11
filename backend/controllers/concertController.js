const db = require('../db_config');

// 1. ดึงคอนเสิร์ตทั้งหมด รองรับทั้ง search และ category (GET /api/concerts)
exports.getAllConcerts = async (req, res) => {
  const { search, category } = req.query;
  let sql = 'SELECT * FROM concerts WHERE 1=1';
  const params = [];

  if (search && search.trim() !== '') {
    sql += ' AND (title LIKE ? OR artist LIKE ? OR venue LIKE ?)';
    const keyword = `%${search.trim()}%`;
    params.push(keyword, keyword, keyword);
  }

  if (category && category.trim() !== '' && category.trim().toLowerCase() !== 'all') {
    sql += ' AND category = ?';
    params.push(category.trim());
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
