const pool = require('../db_config');

// GET /api/resell (ดึงรายการตั๋วมือสองทั้งหมดที่พร้อมขาย)
exports.getAllResellListings = async (req, res) => {
  try {
    const { search } = req.query;
    let sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.status,
        rl.created_at,
        u.user_id AS seller_id,
        u.full_name AS seller_name,
        u.phone AS seller_phone,
        bi.item_id,
        bi.ticket_code,
        bi.price AS original_price,
        s.seat_number,
        z.zone_name,
        sh.show_datetime,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.poster_url
      FROM resell_listings rl
      JOIN users u ON rl.seller_id = u.user_id
      JOIN booking_items bi ON rl.item_id = bi.item_id
      JOIN zones z ON bi.zone_id = z.zone_id
      LEFT JOIN seats s ON bi.seat_id = s.seat_id
      JOIN bookings b ON bi.booking_id = b.booking_id
      JOIN shows sh ON b.show_id = sh.show_id
      JOIN concerts c ON sh.concert_id = c.concert_id
      WHERE rl.status = 'available'
    `;
    const params = [];

    if (search && search.trim() !== '') {
      sql += ` AND (c.title LIKE ? OR z.zone_name LIKE ? OR c.venue LIKE ?)`;
      const queryParam = `%${search.trim()}%`;
      params.push(queryParam, queryParam, queryParam);
    }

    sql += ` ORDER BY rl.created_at DESC`;

    const [rows] = await pool.promise().query(sql, params);
    return res.status(200).json(rows);
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// GET /api/resell/:id (ดูรายละเอียดตั๋วมือสองรายใบ)
exports.getResellListingById = async (req, res) => {
  try {
    const { id } = req.params;
    const sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.status,
        rl.created_at,
        u.user_id AS seller_id,
        u.full_name AS seller_name,
        u.phone AS seller_phone,
        bi.item_id,
        bi.ticket_code,
        bi.price AS original_price,
        s.seat_number,
        z.zone_name,
        sh.show_datetime,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.poster_url
      FROM resell_listings rl
      JOIN users u ON rl.seller_id = u.user_id
      JOIN booking_items bi ON rl.item_id = bi.item_id
      JOIN zones z ON bi.zone_id = z.zone_id
      LEFT JOIN seats s ON bi.seat_id = s.seat_id
      JOIN bookings b ON bi.booking_id = b.booking_id
      JOIN shows sh ON b.show_id = sh.show_id
      JOIN concerts c ON sh.concert_id = c.concert_id
      WHERE rl.listing_id = ?
    `;

    const [rows] = await pool.promise().query(sql, [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Resell ticket listing not found' });
    }

    return res.status(200).json(rows[0]);
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// POST /api/resell (ลงขายตั๋วมือสอง)
exports.createResellListing = async (req, res) => {
  try {
    const { seller_id, item_id, resell_price } = req.body;

    if (!seller_id || !item_id || !resell_price) {
      return res.status(400).json({ 
        message: 'Missing required fields: seller_id, item_id, and resell_price are required' 
      });
    }

    const [ticketCheck] = await pool.promise().query(
      `SELECT bi.item_id, b.user_id 
       FROM booking_items bi 
       JOIN bookings b ON bi.booking_id = b.booking_id 
       WHERE bi.item_id = ?`,
      [item_id]
    );

    if (ticketCheck.length === 0) {
      return res.status(404).json({ message: 'Ticket item not found' });
    }

    const [existingListing] = await pool.promise().query(
      `SELECT listing_id FROM resell_listings WHERE item_id = ? AND status = 'available'`,
      [item_id]
    );

    if (existingListing.length > 0) {
      return res.status(400).json({ message: 'This ticket is already listed for resale' });
    }

    const sql = `
      INSERT INTO resell_listings (seller_id, item_id, resell_price, status)
      VALUES (?, ?, ?, 'available')
    `;
    const [result] = await pool.promise().query(sql, [seller_id, item_id, resell_price]);

    return res.status(201).json({
      message: 'Resell listing created successfully',
      listing_id: result.insertId
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};