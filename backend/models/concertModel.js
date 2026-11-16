
const db = require('../db_config');

class ConcertModel {
  // GET ALL CONCERTS
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

    const params = [];

    if (search && search.trim() !== '') {
      sql += `
        WHERE title LIKE ?
        OR artist LIKE ?
        OR venue LIKE ?
        OR category LIKE ?
      `;

      const keyword = `%${search.trim()}%`;

      params.push(
        keyword,
        keyword,
        keyword,
        keyword
      );
    }

    sql += ` ORDER BY show_datetime ASC`;

    const [results] = await db.query(sql, params);

    return results;
  }

  // GET CONCERT BY ID
  static async getById(id) {
    const sql = `
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
      WHERE concert_id = ?
    `;

    const [results] = await db.query(sql, [id]);

    return results[0] || null;
  }
}

module.exports = ConcertModel;
