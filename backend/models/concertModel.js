const db = require('../db_config');

class ConcertModel {
  // ดึงคอนเสิร์ตทั้งหมด (รองรับการค้นหา)
  static async getAll(search) {
    let sql = 'SELECT * FROM concerts';
    let params = [];

    if (search && search.trim() !== '') {
      sql += ' WHERE title LIKE ? OR venue LIKE ?';
      const keyword = `%${search.trim()}%`;
      params = [keyword, keyword];
    }

    
    const [results] = await db.query(sql, params);
    return results;
  }

  // ดึงคอนเสิร์ตตาม ID
  static async getById(id) {
    const sql = 'SELECT * FROM concerts WHERE concert_id = ?';
    const [results] = await db.query(sql, [id]);
    return results;
  }
}

module.exports = ConcertModel;