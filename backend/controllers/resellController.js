
const db = require('../db_config');

// 1. Get all available resale listings
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
      WHERE rl.status = 'available'
        AND u.is_active = 1
    `;

    const params = [];

    if (concert_id) {
      sql += ` AND c.concert_id = ?`;
      params.push(concert_id);
    }

    if (search && search.trim() !== '') {
      sql += `
        AND (
          c.title LIKE ?
          OR c.artist LIKE ?
          OR t.zone_name LIKE ?
          OR c.venue LIKE ?
        )
      `;

      const keyword = `%${search.trim()}%`;
      params.push(keyword, keyword, keyword, keyword);
    }

    sql += ` ORDER BY rl.created_at DESC`;

    const [rows] = await db.query(sql, params);

    return res.status(200).json(rows);
  } catch (error) {
    console.error('Get resale listings error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve resale listings.'
    });
  }
};


// 2. Get a resale listing by ID
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
      return res.status(404).json({
        message: 'Resale ticket listing not found.'
      });
    }

    return res.status(200).json(rows[0]);
  } catch (error) {
    console.error('Get resale listing detail error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve the resale listing.'
    });
  }
};


// 3. Create a resale listing
exports.createResellListing = async (req, res) => {
  try {
    const sellerId = Number(req.user.user_id);

    const ticketId = req.body.ticket_id || req.body.item_id;
    const { resell_price } = req.body;

    const deliveryType =
      req.body.delivery_type ||
      req.body.delivery_method ||
      'Parcel Shipping';

    const shippingCompany = req.body.shipping_company || null;

    const shippingFee =
      req.body.shipping_fee !== undefined
        ? Number(req.body.shipping_fee)
        : 0;

    const deliveryNote = req.body.delivery_note || null;
    const bankName = req.body.bank_name || null;
    const bankAccountName = req.body.bank_account_name || null;

    const bankAccountNumber =
      req.body.bank_account_number ||
      req.body.bank_account_no ||
      null;

    if (!ticketId || resell_price === undefined || resell_price === null) {
      return res.status(400).json({
        message: 'Ticket ID and selling price are required.'
      });
    }

    const numericPrice = Number(resell_price);

    if (!Number.isFinite(numericPrice) || numericPrice <= 0) {
      return res.status(400).json({
        message: 'Please enter a valid selling price.'
      });
    }

    if (!Number.isFinite(shippingFee) || shippingFee < 0) {
      return res.status(400).json({
        message: 'Invalid shipping fee.'
      });
    }

    // Check seller verification
    const [users] = await db.query(
      'SELECT is_verified FROM users WHERE user_id = ?',
      [sellerId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        message: 'User not found.'
      });
    }

    if (Number(users[0].is_verified) !== 1) {
      return res.status(403).json({
        message: 'Please complete seller identity verification before listing tickets.'
      });
    }

    // Check ticket ownership
    const [ticketCheck] = await db.query(
      `SELECT ticket_id, user_id, original_price
       FROM tickets
       WHERE ticket_id = ?`,
      [ticketId]
    );

    if (ticketCheck.length === 0) {
      return res.status(404).json({
        message: 'Ticket not found.'
      });
    }

    if (Number(ticketCheck[0].user_id) !== sellerId) {
      return res.status(403).json({
        message: 'You do not own this ticket.'
      });
    }

    const originalPrice = Number(ticketCheck[0].original_price);

    if (originalPrice > 0 && numericPrice > originalPrice * 5) {
      return res.status(400).json({
        message: 'The selling price cannot exceed 5 times the original price.'
      });
    }

    // Check whether the ticket is already listed
    const [existingListing] = await db.query(
      `SELECT listing_id
       FROM resell_listings
       WHERE ticket_id = ?
         AND status = 'available'`,
      [ticketId]
    );

    if (existingListing.length > 0) {
      return res.status(409).json({
        message: 'This ticket is already listed for resale.'
      });
    }

    const [result] = await db.query(
      `INSERT INTO resell_listings
       (
         ticket_id,
         seller_id,
         resell_price,
         delivery_type,
         shipping_company,
         shipping_fee,
         delivery_note,
         bank_name,
         bank_account_name,
         bank_account_number,
         status
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available')`,
      [
        ticketId,
        sellerId,
        numericPrice,
        deliveryType,
        shippingCompany,
        shippingFee,
        deliveryNote,
        bankName,
        bankAccountName,
        bankAccountNumber
      ]
    );

    return res.status(201).json({
      message: 'Resale listing created successfully.',
      listing_id: result.insertId
    });

  } catch (error) {
    console.error('Create resale listing error:', error.message);

    return res.status(500).json({
      message: 'Unable to create the resale listing.'
    });
  }
};


// 4. Cancel a resale listing
exports.cancelResellListing = async (req, res) => {
  const listingId = req.params.id;
  const userId = req.user.user_id;

  let conn;

  try {
    conn = await db.getConnection();

    await conn.beginTransaction();

    const [rows] = await conn.query(
      `SELECT *
       FROM resell_listings
       WHERE listing_id = ?
       FOR UPDATE`,
      [listingId]
    );

    if (rows.length === 0) {
      await conn.rollback();

      return res.status(404).json({
        message: 'Listing not found.'
      });
    }

    if (
      Number(rows[0].seller_id) !== Number(userId) &&
      req.user.role !== 'admin'
    ) {
      await conn.rollback();

      return res.status(403).json({
        message: 'Only the seller or an administrator can cancel this listing.'
      });
    }

    if (rows[0].status === 'sold') {
      await conn.rollback();

      return res.status(400).json({
        message: 'Cannot cancel a listing that has already been sold.'
      });
    }

    await conn.query(
      `UPDATE resell_listings
       SET status = 'cancelled'
       WHERE listing_id = ?`,
      [listingId]
    );

    await conn.query(
      `UPDATE payments
       SET status = 'cancelled'
       WHERE listing_id = ?
         AND status = 'pending'`,
      [listingId]
    );

    await conn.commit();

    return res.status(200).json({
      message: 'Listing cancelled successfully.',
      listing_id: Number(listingId),
      status: 'cancelled'
    });

  } catch (error) {
    if (conn) {
      await conn.rollback();
    }

    console.error('Cancel resale listing error:', error.message);

    return res.status(500).json({
      message: 'Unable to cancel the resale listing.'
    });

  } finally {
    if (conn) {
      conn.release();
    }
  }
};


// 5. Get resale listings created by the logged-in user
exports.getMyResellListings = async (req, res) => {
  try {
    const userId = req.user.user_id;

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

    const [rows] = await db.query(sql, [userId]);

    return res.status(200).json(rows);

  } catch (error) {
    console.error('Get my resale listings error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve your resale listings.'
    });
  }
};


// 6. Get tickets owned by the logged-in user that are available for resale
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
        AND NOT EXISTS (
          SELECT 1
          FROM resell_listings rl
          WHERE rl.ticket_id = t.ticket_id
            AND rl.status = 'available'
        )
      ORDER BY t.ticket_id DESC
    `;

    const [rows] = await db.query(sql, [userId]);

    return res.status(200).json(rows);

  } catch (error) {
    console.error('Get my tickets error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve your tickets.'
    });
  }
};


// 7. Submit seller identity verification request
exports.registerSeller = async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { full_name, national_id } = req.body;

    if (
      typeof full_name !== 'string' ||
      !full_name.trim() ||
      typeof national_id !== 'string' ||
      !/^\d{13}$/.test(national_id)
    ) {
      return res.status(400).json({
        message: 'Please enter your full name and a valid 13-digit national ID.'
      });
    }

    // Validate Thai national ID checksum
    const digits = national_id.split('').map(Number);

    const sum = digits.slice(0, 12).reduce(
      (total, digit, index) => total + digit * (13 - index),
      0
    );

    if ((11 - (sum % 11)) % 10 !== digits[12]) {
      return res.status(400).json({
        message: 'Invalid national ID number.'
      });
    }

    const [users] = await db.query(
      'SELECT is_verified FROM users WHERE user_id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        message: 'User not found.'
      });
    }

    if (Number(users[0].is_verified) === 1) {
      return res.status(409).json({
        message: 'Your seller identity has already been verified.'
      });
    }

    const [existing] = await db.query(
      `SELECT verification_status
       FROM seller_verifications
       WHERE user_id = ?
       ORDER BY submitted_at DESC
       LIMIT 1`,
      [userId]
    );

    if (
      existing.length > 0 &&
      existing[0].verification_status === 'pending'
    ) {
      return res.status(409).json({
        message: 'You already have a verification request pending review.'
      });
    }

    // National ID encryption must be configured before accepting real submissions.
    // Do not store plain-text national ID numbers.
    const { encryptNationalId } = require('../utils/nationalIdEncryption');
    const encryptedId = encryptNationalId(national_id);

    await db.query(
      `INSERT INTO seller_verifications
       (
         user_id,
         full_name,
         national_id_encrypted,
         verification_status
       )
       VALUES (?, ?, ?, 'pending')`,
      [userId, full_name.trim(), encryptedId]
    );

    return res.status(201).json({
      message: 'Your identity verification request has been submitted successfully.'
    });

  } catch (error) {
    console.error('Register seller error:', error.message);

    return res.status(500).json({
      message: 'Unable to submit your verification request.'
    });
  }
};


// 8. Get seller verification status
exports.getSellerStatus = async (req, res) => {
  try {
    const userId = req.user.user_id;

    const [rows] = await db.query(
      `SELECT
         verification_status,
         submitted_at,
         reviewed_at,
         rejection_reason
       FROM seller_verifications
       WHERE user_id = ?
       ORDER BY submitted_at DESC
       LIMIT 1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(200).json({
        status: 'not_submitted',
        is_verified: false
      });
    }

    return res.status(200).json({
      status: rows[0].verification_status,
      is_verified: rows[0].verification_status === 'approved',
      submitted_at: rows[0].submitted_at,
      reviewed_at: rows[0].reviewed_at,
      rejection_reason: rows[0].rejection_reason
    });

  } catch (error) {
    console.error('Get seller status error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve seller verification status.'
    });
  }
};
