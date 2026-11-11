const db = require('../db_config');

// 1. ดึงรายการตั๋วมือสองที่สถานะเป็น available (GET /api/resell/listings)
exports.getAllResellListings = async (req, res) => {
  try {
    const { search, concert_id } = req.query;
    let sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.delivery_type,
        rl.shipping_company,
        rl.shipping_fee,
        rl.delivery_note,
        rl.status,
        rl.created_at,
        u.user_id AS seller_id,
        u.full_name AS seller_name,
        u.is_verified AS seller_verified,
        t.ticket_id,
        CONCAT(LEFT(t.ticket_code, 4), '-****') AS ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.artist,
        c.category,
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
      sql += ` AND (c.title LIKE ? OR c.artist LIKE ? OR t.zone_name LIKE ? OR c.venue LIKE ?)`;
      const keyword = `%${search.trim()}%`;
      params.push(keyword, keyword, keyword, keyword);
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
        rl.delivery_type,
        rl.shipping_company,
        rl.shipping_fee,
        rl.delivery_note,
        rl.status,
        rl.created_at,
        u.user_id AS seller_id,
        u.full_name AS seller_name,
        u.is_verified AS seller_verified,
        t.ticket_id,
        CONCAT(LEFT(t.ticket_code, 4), '-****') AS ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.artist,
        c.category,
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
    const seller_id = req.user.user_id;
    const ticket_id = req.body.ticket_id || req.body.item_id;
    const { resell_price } = req.body;
    const delivery_type = req.body.delivery_type || req.body.delivery_method || 'Parcel Shipping';
    const shipping_company = req.body.shipping_company || null;
    const shipping_fee = req.body.shipping_fee !== undefined ? Number(req.body.shipping_fee) : 0.0;
    const delivery_note = req.body.delivery_note || null;
    const bank_name = req.body.bank_name || null;
    const bank_account_name = req.body.bank_account_name || null;
    const bank_account_number = req.body.bank_account_number || req.body.bank_account_no || null;

    if (!ticket_id || resell_price === undefined || resell_price === null) {
      return res.status(400).json({
        message: 'Missing required fields: ticket_id and resell_price are required',
      });
    }

    const numericPrice = Number(resell_price);
    if (!Number.isFinite(numericPrice) || numericPrice <= 0 || numericPrice > 1000000) {
      return res.status(400).json({
        message: 'Invalid resell_price: must be greater than 0 and not exceed 1,000,000 THB',
      });
    }

    const [ticketCheck] = await db.query(
      'SELECT ticket_id, user_id, original_price FROM tickets WHERE ticket_id = ?',
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

    const originalPrice = Number(ticketCheck[0].original_price);
    if (originalPrice > 0 && numericPrice > originalPrice * 5) {
      return res.status(400).json({
        message: 'The selling price exceeds the maximum allowed markup (5x original price)',
      });
    }

    const [existingListing] = await db.query(
      "SELECT listing_id FROM resell_listings WHERE ticket_id = ? AND status = 'available'",
      [ticket_id]
    );

    if (existingListing.length > 0) {
      return res.status(400).json({ message: 'This ticket is already listed for resale' });
    }

    const [result] = await db.query(
      `INSERT INTO resell_listings 
       (ticket_id, seller_id, resell_price, delivery_type, shipping_company, shipping_fee, delivery_note, bank_name, bank_account_name, bank_account_number, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available')`,
      [
        ticket_id,
        seller_id,
        numericPrice,
        delivery_type,
        shipping_company,
        shipping_fee,
        delivery_note,
        bank_name,
        bank_account_name,
        bank_account_number,
      ]
    );

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

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.query(
      'SELECT * FROM resell_listings WHERE listing_id = ? FOR UPDATE',
      [listingId]
    );

    if (rows.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Listing not found.' });
    }

    if (rows[0].seller_id !== userId && req.user.role !== 'admin') {
      await conn.rollback();
      return res.status(403).json({
        message: 'Forbidden: Only the seller can cancel this listing.',
      });
    }

    if (rows[0].status === 'sold') {
      await conn.rollback();
      return res.status(400).json({
        message: 'Cannot cancel a listing that has already been sold.',
      });
    }

    await conn.query(
      "UPDATE resell_listings SET status = 'cancelled' WHERE listing_id = ?",
      [listingId]
    );

    // ยกเลิกออเดอร์ที่ยังค้างสถานะ pending ของรายการนี้ด้วย
    await conn.query(
      "UPDATE payments SET status = 'cancelled' WHERE listing_id = ? AND status = 'pending'",
      [listingId]
    );

    await conn.commit();

    return res.status(200).json({
      message: 'Listing cancelled successfully.',
      listing_id: Number(listingId),
      status: 'cancelled',
    });
  } catch (err) {
    await conn.rollback();
    return res.status(500).json({ message: 'Database Error', error: err.message });
  } finally {
    conn.release();
  }
};

// 5. ดึงรายการตั๋วที่ตัวเองกำลังประกาศขาย (GET /api/resell/my-listings)
exports.getMyResellListings = async (req, res) => {
  try {
    const sql = `
      SELECT 
        rl.listing_id,
        rl.resell_price,
        rl.delivery_type,
        rl.shipping_company,
        rl.shipping_fee,
        rl.delivery_note,
        rl.bank_name,
        rl.bank_account_name,
        rl.bank_account_number,
        rl.status,
        rl.created_at,
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        t.original_price,
        c.concert_id,
        c.title AS concert_title,
        c.artist,
        c.category,
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
        c.artist,
        c.category,
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
