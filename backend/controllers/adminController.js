const db = require('../db_config');

// 1. ดึงรายชื่อผู้ใช้ทั้งหมด พร้อมรายการตั๋วที่ถือครองและรายการขายต่อ (GET /api/admin/users)
exports.getAllUsers = async (req, res) => {
  const usersSql = `
    SELECT 
      u.user_id,
      u.username,
      u.email,
      u.full_name,
      u.phone,
      u.role,
      u.is_verified,
      u.is_active,
      u.created_at,
      (SELECT COUNT(*) FROM resell_listings rl WHERE rl.seller_id = u.user_id AND rl.status = 'sold') AS tickets_sold,
      (SELECT COUNT(*) FROM payments p WHERE p.buyer_id = u.user_id AND p.status IN ('completed', 'paid')) AS tickets_bought
    FROM users u
    ORDER BY u.user_id ASC
  `;

  const ticketsSql = `
    SELECT 
      t.ticket_id,
      t.user_id,
      t.ticket_code AS ticketCode,
      t.zone_name AS zone,
      t.seat_number AS seat,
      t.original_price AS originalPrice,
      c.title AS concert,
      c.venue,
      p.amount AS paidAmount,
      p.shipping_fee AS shippingFee,
      p.delivery_method,
      p.payment_method AS paymentMethod,
      p.paid_at AS paidAt,
      seller.full_name AS sellerName,
      seller.email AS sellerEmail,
      seller.phone AS sellerPhone
    FROM tickets t
    JOIN concerts c ON t.concert_id = c.concert_id
    LEFT JOIN resell_listings rl ON rl.ticket_id = t.ticket_id AND rl.status = 'sold'
    LEFT JOIN payments p ON p.listing_id = rl.listing_id AND p.buyer_id = t.user_id AND p.status IN ('completed', 'paid')
    LEFT JOIN users seller ON rl.seller_id = seller.user_id
    ORDER BY t.ticket_id DESC
  `;

  const resellSql = `
    SELECT 
      rl.listing_id AS listingId,
      rl.seller_id,
      rl.resell_price AS resellPrice,
      rl.delivery_type AS deliveryType,
      rl.shipping_fee AS shippingFee,
      rl.status,
      t.ticket_code AS ticketCode,
      t.zone_name AS zone,
      t.seat_number AS seat,
      c.title AS concert,
      p.shipping_status AS shippingStatus
    FROM resell_listings rl
    JOIN tickets t ON rl.ticket_id = t.ticket_id
    JOIN concerts c ON t.concert_id = c.concert_id
    LEFT JOIN payments p ON p.listing_id = rl.listing_id AND p.status IN ('completed', 'paid')
    ORDER BY rl.listing_id DESC
  `;

  try {
    const [users] = await db.query(usersSql);
    const [tickets] = await db.query(ticketsSql);
    const [listings] = await db.query(resellSql);

    const enrichedUsers = users.map((u) => ({
      ...u,
      tickets_sold: Number(u.tickets_sold || 0),
      tickets_bought: Number(u.tickets_bought || 0),
      ownedTickets: tickets
        .filter((t) => t.user_id === u.user_id)
        .map((t) => ({
          ...t,
          originalPrice: Number(t.originalPrice || 0),
          paidAmount: t.paidAmount != null ? Number(t.paidAmount) : null,
          shippingFee: Number(t.shippingFee || 0),
        })),
      resellListings: listings
        .filter((l) => l.seller_id === u.user_id)
        .map((l) => ({
          ...l,
          resellPrice: Number(l.resellPrice || 0),
          shippingFee: Number(l.shippingFee || 0),
        })),
    }));

    return res.status(200).json(enrichedUsers);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 2. ระงับ / ปลดระงับบัญชีผู้ใช้ (PATCH /api/admin/users/:id/status)
exports.updateUserStatus = async (req, res) => {
  const userId = Number(req.params.id);
  const { is_active } = req.body;

  if (is_active === undefined || ![0, 1, true, false].includes(is_active)) {
    return res.status(400).json({
      message: 'Please specify is_active as 0 (suspended) or 1 (active).',
    });
  }

  const activeValue = is_active ? 1 : 0;

  if (req.user.user_id === userId && activeValue === 0) {
    return res.status(400).json({
      message: 'Admin cannot suspend their own account.',
    });
  }

  try {
    const [result] = await db.query(
      'UPDATE users SET is_active = ? WHERE user_id = ?',
      [activeValue, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.status(200).json({
      message:
        activeValue === 1
          ? 'User account activated successfully.'
          : 'User account suspended successfully.',
      user_id: userId,
      is_active: activeValue,
    });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 3. ยืนยันตัวตนผู้ขาย KYC (PATCH /api/admin/users/:id/verify)
exports.verifySeller = async (req, res) => {
  const userId = Number(req.params.id);
  const { is_verified } = req.body;

  if (is_verified === undefined || ![0, 1, true, false].includes(is_verified)) {
    return res.status(400).json({
      message: 'Please specify is_verified as 0 or 1.',
    });
  }

  const verifiedValue = is_verified ? 1 : 0;

  try {
    const [result] = await db.query(
      'UPDATE users SET is_verified = ? WHERE user_id = ?',
      [verifiedValue, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found.' });
    }

    return res.status(200).json({
      message:
        verifiedValue === 1
          ? 'Seller identity verified successfully.'
          : 'Seller verification revoked.',
      user_id: userId,
      is_verified: verifiedValue,
    });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 4. ลบบัญชีผู้ใช้ (DELETE /api/admin/users/:id)
exports.deleteUser = async (req, res) => {
  const userId = Number(req.params.id);

  if (req.user.user_id === userId) {
    return res.status(400).json({
      message: 'Admin cannot delete their own account.',
    });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    await conn.query(
      "UPDATE resell_listings SET status = 'cancelled' WHERE seller_id = ? AND status = 'available'",
      [userId]
    );

    const [result] = await conn.query('DELETE FROM users WHERE user_id = ?', [userId]);

    if (result.affectedRows === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'User not found.' });
    }

    await conn.commit();
    return res.status(200).json({
      message: 'User deleted successfully.',
      user_id: userId,
    });
  } catch (err) {
    await conn.rollback();
    return res.status(500).json({ message: 'Database Error', error: err.message });
  } finally {
    conn.release();
  }
};