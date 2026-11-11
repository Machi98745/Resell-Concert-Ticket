const db = require('../db_config');

class ConcertModel {
  // 1. ดึงคอนเสิร์ตทั้งหมด (รองรับทั้ง search และ category)
  static async getAll(search, category) {
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

    const [results] = await db.query(sql, params);
    return results;
  }

  // 2. ดึงรายละเอียดคอนเสิร์ตตาม ID
  static async getById(id) {
    const sql = 'SELECT * FROM concerts WHERE concert_id = ?';
    const [results] = await db.query(sql, [id]);
    return results;
  }
}

module.exports = ConcertModel;
