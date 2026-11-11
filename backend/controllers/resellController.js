const db = require('../db_config');

// 1. ดึงรายการตั๋วมือสองที่สถานะเป็น available (GET /api/resell/listings)
exports.getAllResellListings = async (req, res) => {
  try {
    const { search, concert_id } = req.query;
    let sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.status,
        rl.created_at,
        u.user_id AS seller_id,
        u.full_name AS seller_name,
        u.phone AS seller_phone,
        u.is_verified AS seller_verified,
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM resell_listings rl
      JOIN users u ON rl.seller_id = u.user_id
      JOIN tickets t ON rl.ticket_id = t.ticket_id
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE rl.status = 'available' AND u.is_active = 1
    `;
    const params = [];

    if (concert_id) {
      sql += ` AND c.concert_id = ?`;
      params.push(concert_id);
    }

    if (search && search.trim() !== '') {
      sql += ` AND (c.title LIKE ? OR t.zone_name LIKE ? OR c.venue LIKE ?)`;
      const keyword = `%${search.trim()}%`;
      params.push(keyword, keyword, keyword);
    }

    sql += ` ORDER BY rl.created_at DESC`;

    const [rows] = await db.query(sql, params);
    return res.status(200).json(rows);
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// 2. ดูรายละเอียดตั๋วมือสองรายใบ (GET /api/resell/:id)
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
        u.is_verified AS seller_verified,
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM resell_listings rl
      JOIN users u ON rl.seller_id = u.user_id
      JOIN tickets t ON rl.ticket_id = t.ticket_id
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE rl.listing_id = ?
    `;

    const [rows] = await db.query(sql, [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Resell ticket listing not found' });
    }
    return res.status(200).json(rows[0]);
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// 3. ฝากขายตั๋วมือสอง (POST /api/resell/create)
exports.createResellListing = async (req, res) => {
  try {
    const seller_id = (req.user && req.user.user_id) || req.body.seller_id;
    const ticket_id = req.body.ticket_id || req.body.item_id;
    const {
      resell_price,
      delivery_method,
      shipping_fee,
      bank_name,
      bank_account_no,
      bank_account_name,
    } = req.body;

    if (!seller_id || !ticket_id || !resell_price) {
      return res.status(400).json({
        message: 'Missing required fields: ticket_id (or item_id) and resell_price are required',
      });
    }

    const [ticketCheck] = await db.query(
      'SELECT ticket_id, user_id FROM tickets WHERE ticket_id = ?',
      [ticket_id]
    );

    if (ticketCheck.length === 0) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    if (ticketCheck[0].user_id !== Number(seller_id)) {
      return res.status(403).json({
        message: 'Forbidden: You are not the owner of this ticket and cannot list it for resale',
      });
    }

    const [existingListing] = await db.query(
      "SELECT listing_id FROM resell_listings WHERE ticket_id = ? AND status = 'available'",
      [ticket_id]
    );

    if (existingListing.length > 0) {
      return res.status(400).json({ message: 'This ticket is already listed for resale' });
    }

    let result;
    try {
      [result] = await db.query(
        `INSERT INTO resell_listings 
         (seller_id, ticket_id, resell_price, delivery_method, shipping_fee, bank_name, bank_account_no, bank_account_name, status) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'available')`,
        [
          seller_id,
          ticket_id,
          resell_price,
          delivery_method || 'Parcel Shipping',
          shipping_fee !== undefined ? Number(shipping_fee) : 50.0,
          bank_name || null,
          bank_account_no || null,
          bank_account_name || null,
        ]
      );
    } catch (_) {
      [result] = await db.query(
        "INSERT INTO resell_listings (seller_id, ticket_id, resell_price, status) VALUES (?, ?, ?, 'available')",
        [seller_id, ticket_id, resell_price]
      );
    }

    return res.status(201).json({
      message: 'Resell listing created successfully',
      listing_id: result.insertId,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// 4. ยกเลิกประกาศขายตั๋วมือสอง (PATCH /api/resell/:id/cancel)
exports.cancelResellListing = async (req, res) => {
  const listingId = req.params.id;
  const userId = req.user.user_id;

  try {
    const [rows] = await db.query(
      'SELECT * FROM resell_listings WHERE listing_id = ?',
      [listingId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Listing not found.' });
    }

    if (rows[0].seller_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Forbidden: Only the seller can cancel this listing.',
      });
    }

    if (rows[0].status === 'sold') {
      return res.status(400).json({
        message: 'Cannot cancel a listing that has already been sold.',
      });
    }

    await db.query(
      "UPDATE resell_listings SET status = 'cancelled' WHERE listing_id = ?",
      [listingId]
    );

    return res.status(200).json({
      message: 'Listing cancelled successfully.',
      listing_id: Number(listingId),
      status: 'cancelled',
    });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 5. ดึงรายการตั๋วที่ตัวเองกำลังประกาศขาย (GET /api/resell/my-listings)
exports.getMyResellListings = async (req, res) => {
  try {
    const sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.status,
        rl.created_at,
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM resell_listings rl
      JOIN tickets t ON rl.ticket_id = t.ticket_id
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE rl.seller_id = ?
      ORDER BY rl.created_at DESC
    `;
    const [rows] = await db.query(sql, [req.user.user_id]);
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 6. ดึงรายการตั๋วของผู้ใช้ที่ล็อกอินอยู่ (GET /api/user/my-tickets)
exports.getMyTickets = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const sql = `
      SELECT 
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM tickets t
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE t.user_id = ?
        AND t.ticket_id NOT IN (
          SELECT ticket_id FROM resell_listings WHERE status = 'available'
        )
      ORDER BY t.ticket_id DESC
    `;

    const [rows] = await db.query(sql, [userId]);
    return res.status(200).json(rows);
  } catch (error) {
    return res.status(500).json({ message: 'Server Error', error: error.message });
  }
};
