const db = require('../db_config');

class ConcertModel {
  // ดึงคอนเสิร์ตทั้งหมด (รองรับการค้นหาชื่อคอนเสิร์ต ศิลปิน สถานที่ และหมวดหมู่)
  static async getAll(search) {
    let sql = `
      SELECT
        concert_id,
        title,
        artist,
        category,
        description,
        venue,
        show_datetime,
        poster_url,
        created_at
      FROM concerts
    `;
    let params = [];

    if (search && search.trim() !== '') {
      sql += ' WHERE title LIKE ? OR artist LIKE ? OR venue LIKE ? OR category LIKE ?';
      const keyword = `%${search.trim()}%`;
      params = [keyword, keyword, keyword, keyword];
    }

    sql += ' ORDER BY show_datetime ASC';

    const [results] = await db.query(sql, params);
    return results;
  }

  // ดึงคอนเสิร์ตตาม ID
  static async getById(id) {
    const sql = 'SELECT * FROM concerts WHERE concert_id = ?';
    const [results] = await db.query(sql, [id]);
    return results;
  }

  // เพิ่มคอนเสิร์ตใหม่
  static async create({ title, artist, category, description, venue, show_datetime, poster_url }) {
    const sql = `
      INSERT INTO concerts (title, artist, category, description, venue, show_datetime, poster_url)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const [result] = await db.query(sql, [
      title,
      artist || null,
      category || null,
      description || null,
      venue,
      show_datetime,
      poster_url || null,
    ]);
    return result.insertId;
  }

  // แก้ไขข้อมูลคอนเสิร์ต
  static async update(id, { title, artist, category, description, venue, show_datetime, poster_url }) {
    const sql = `
      UPDATE concerts
      SET title = ?, artist = ?, category = ?, description = ?, venue = ?, show_datetime = ?, poster_url = ?
      WHERE concert_id = ?
    `;
    const [result] = await db.query(sql, [
      title,
      artist || null,
      category || null,
      description || null,
      venue,
      show_datetime,
      poster_url || null,
      id,
    ]);
    return result.affectedRows;
  }

  // ลบคอนเสิร์ต
  static async delete(id) {
    const sql = 'DELETE FROM concerts WHERE concert_id = ?';
    const [result] = await db.query(sql, [id]);
    return result.affectedRows;
  }
}

module.exports = ConcertModel;