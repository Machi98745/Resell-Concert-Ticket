const db = require('../db_config');

// 1. ดึงรายชื่อผู้ใช้ทั้งหมด พร้อมจำนวนตั๋วที่ขาย/ซื้อ (GET /api/admin/users)
exports.getAllUsers = async (req, res) => {
  const sql = `
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
  try {
    const [results] = await db.query(sql);
    return res.status(200).json(results);
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

    // ยกเลิกประกาศขายที่ยังค้างอยู่ของผู้ใช้นี้ก่อนลบ
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
