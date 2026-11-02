const db = require('../db_config');

// 1. ดึงรายการคอนเสิร์ตทั้งหมด
exports.getAllConcerts = (req, res) => {
  const { search } = req.query;
  let sql = "SELECT * FROM concerts";
  let params = [];

  if (search && search.trim() !== '') {
    sql += " WHERE name LIKE ? OR venue LIKE ?";
    const keyword = `%${search.trim()}%`;
    params = [keyword, keyword];
  }

  db.query(sql, params, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database Error', error: err.message });
    }
    res.status(200).json(results);
  });
};

// 2. ดึงรายละเอียดคอนเสิร์ตตาม ID
exports.getConcertById = (req, res) => {
  const { id } = req.params;
  const sql = "SELECT * FROM concerts WHERE concert_id = ?";

  db.query(sql, [id], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database Error', error: err.message });
    }
    if (results.length === 0) {
      return res.status(404).json({ message: 'Concert not found' });
    }
    res.status(200).json(results[0]);
  });
};