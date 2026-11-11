const db = require('../db_config');

const PAYMENT_TIMEOUT_MINUTES = 15;
const COMMISSION_RATE = 0.02;
const PARCEL_SHIPPING_FEE = 50;

// 1. สร้างรายการสั่งซื้อตั๋ว + เริ่มจับเวลา 15 นาที (POST /api/payments/create)
exports.createPayment = async (req, res) => {
  const buyerId = req.user.user_id;
  const { listing_id } = req.body;
  const receive_method = req.body.receive_method || req.body.delivery_method;
  const receive_details = req.body.receive_details || req.body.shipping_info;

  if (!listing_id || !receive_method || !receive_details) {
    return res.status(400).json({
      message: 'Please provide listing_id, receive_method, and receive_details.',
    });
  }

  let normalizedMethod = receive_method;
  if (receive_method === 'Parcel Shipping') normalizedMethod = 'delivery';
  if (receive_method === 'Digital Transfer') normalizedMethod = 'meetup';

  if (!['delivery', 'meetup', 'Parcel Shipping', 'Digital Transfer'].includes(receive_method)) {
    return res.status(400).json({
      message: 'receive_method must be "delivery", "meetup", "Parcel Shipping", or "Digital Transfer".',
    });
  }

  try {
    const [listings] = await db.query(
      'SELECT * FROM resell_listings WHERE listing_id = ?',
      [listing_id]
    );

    if (listings.length === 0) {
      return res.status(404).json({ message: 'Resell ticket listing not found.' });
    }

    const listing = listings[0];

    if (listing.status !== 'available') {
      return res.status(400).json({
        message: 'This ticket has already been sold or cancelled.',
      });
    }

    if (listing.seller_id === buyerId) {
      return res.status(400).json({
        message: 'You cannot purchase your own resell ticket.',
      });
    }

    const [activePayments] = await db.query(
      `SELECT * FROM payments
       WHERE listing_id = ? AND status = 'pending' AND expires_at > NOW()`,
      [listing_id]
    );

    if (activePayments.length > 0 && activePayments[0].buyer_id !== buyerId) {
      return res.status(409).json({
        message:
          'Another buyer is currently in the payment process for this ticket. Please wait up to 15 minutes.',
      });
    }

    await db.query(
      `UPDATE payments
       SET status = 'expired'
       WHERE listing_id = ? AND status = 'pending' AND expires_at <= NOW()`,
      [listing_id]
    );

    const basePrice = Number(listing.resell_price);
    const commissionFee = Math.round(basePrice * COMMISSION_RATE);
    const shippingFee = normalizedMethod === 'delivery' ? PARCEL_SHIPPING_FEE : 0;
    const totalAmount = basePrice + commissionFee + shippingFee;

    let result;
    try {
      [result] = await db.query(
        `INSERT INTO payments
          (listing_id, buyer_id, amount, commission_fee, shipping_fee, receive_method, receive_details, status, expires_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
        [
          listing_id,
          buyerId,
          totalAmount,
          commissionFee,
          shippingFee,
          normalizedMethod,
          receive_details,
          PAYMENT_TIMEOUT_MINUTES,
        ]
      );
    } catch (_) {
      [result] = await db.query(
        `INSERT INTO payments
          (listing_id, buyer_id, amount, receive_method, receive_details, status, expires_at)
         VALUES (?, ?, ?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
        [
          listing_id,
          buyerId,
          totalAmount,
          normalizedMethod,
          receive_details,
          PAYMENT_TIMEOUT_MINUTES,
        ]
      );
    }

    const [createdRows] = await db.query(
      'SELECT *, TIMESTAMPDIFF(SECOND, NOW(), expires_at) AS remaining_seconds FROM payments WHERE payment_id = ?',
      [result.insertId]
    );

    return res.status(201).json({
      message: 'Order created successfully. Please complete payment within 15 minutes.',
      payment: createdRows[0],
    });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 2. ยืนยันการชำระเงินภายใน 15 นาที + โอนกรรมสิทธิ์ตั๋ว (POST /api/payments/:id/confirm)
exports.confirmPayment = async (req, res) => {
  const paymentId = req.params.id;
  const buyerId = req.user.user_id;

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const [payments] = await conn.query(
      `SELECT p.*, rl.ticket_id, rl.status AS listing_status
       FROM payments p
       JOIN resell_listings rl ON p.listing_id = rl.listing_id
       WHERE p.payment_id = ?
       FOR UPDATE`,
      [paymentId]
    );

    if (payments.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Payment record not found.' });
    }

    const payment = payments[0];

    if (payment.buyer_id !== buyerId) {
      await conn.rollback();
      return res.status(403).json({
        message: 'Forbidden: You do not own this payment record.',
      });
    }

    if (payment.status === 'paid') {
      await conn.rollback();
      return res.status(400).json({
        message: 'This payment has already been completed.',
      });
    }

    if (payment.status !== 'pending') {
      await conn.rollback();
      return res.status(400).json({
        message: `Cannot confirm payment with status "${payment.status}".`,
      });
    }

    const [timeCheck] = await conn.query(
      'SELECT NOW() > ? AS is_expired',
      [payment.expires_at]
    );

    if (timeCheck[0].is_expired === 1) {
      await conn.query(
        'UPDATE payments SET status = "expired" WHERE payment_id = ?',
        [paymentId]
      );
      await conn.commit();
      return res.status(400).json({
        message: 'Payment timeout (exceeded 15 minutes). Please create a new order.',
      });
    }

    if (payment.listing_status !== 'available') {
      await conn.rollback();
      return res.status(400).json({
        message: 'This ticket is no longer available.',
      });
    }

    await conn.query(
      'UPDATE payments SET status = "paid", paid_at = NOW() WHERE payment_id = ?',
      [paymentId]
    );

    await conn.query(
      'UPDATE resell_listings SET status = "sold" WHERE listing_id = ?',
      [payment.listing_id]
    );

    await conn.query(
      'UPDATE tickets SET user_id = ? WHERE ticket_id = ?',
      [buyerId, payment.ticket_id]
    );

    await conn.commit();

    return res.status(200).json({
      message: 'Payment completed and ticket ownership transferred successfully.',
      payment_id: Number(paymentId),
      listing_id: payment.listing_id,
      ticket_id: payment.ticket_id,
      receive_method: payment.receive_method,
      receive_details: payment.receive_details,
      status: 'paid',
    });
  } catch (err) {
    await conn.rollback();
    return res.status(500).json({ message: 'Database Error', error: err.message });
  } finally {
    conn.release();
  }
};

// 3. ยกเลิกคำสั่งซื้อ (POST /api/payments/:id/cancel)
exports.cancelPayment = async (req, res) => {
  const paymentId = req.params.id;
  const buyerId = req.user.user_id;

  try {
    const [payments] = await db.query(
      'SELECT * FROM payments WHERE payment_id = ?',
      [paymentId]
    );

    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment record not found.' });
    }

    const payment = payments[0];

    if (payment.buyer_id !== buyerId) {
      return res.status(403).json({
        message: 'Forbidden: You do not own this payment record.',
      });
    }

    if (payment.status === 'paid') {
      return res.status(400).json({
        message: 'Cannot cancel a completed payment.',
      });
    }

    try {
      await db.query(
        'UPDATE payments SET status = "cancelled" WHERE payment_id = ?',
        [paymentId]
      );
    } catch (_) {
      await db.query(
        'UPDATE payments SET status = "expired" WHERE payment_id = ?',
        [paymentId]
      );
    }

    return res.status(200).json({
      message: 'Order cancelled successfully.',
      payment_id: Number(paymentId),
      status: 'cancelled',
    });
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 4. ดึงประวัติคำสั่งซื้อทั้งหมดของผู้ใช้ (GET /api/payments/my-orders)
exports.getMyOrders = async (req, res) => {
  const buyerId = req.user.user_id;

  try {
    await db.query(
      `UPDATE payments
       SET status = 'expired'
       WHERE buyer_id = ? AND status = 'pending' AND expires_at <= NOW()`,
      [buyerId]
    );

    const sql = `
      SELECT 
        p.*,
        GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), p.expires_at)) AS remaining_seconds,
        rl.resell_price,
        t.ticket_id,
        t.ticket_code,
        t.zone_name,
        t.seat_number,
        c.concert_id,
        c.title AS concert_title,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM payments p
      JOIN resell_listings rl ON p.listing_id = rl.listing_id
      JOIN tickets t ON rl.ticket_id = t.ticket_id
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE p.buyer_id = ?
      ORDER BY p.created_at DESC
    `;

    const [orders] = await db.query(sql, [buyerId]);
    return res.status(200).json(orders);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};

// 5. เช็กสถานะการชำระเงินและเวลาที่เหลือ (GET /api/payments/:id)
exports.getPaymentById = async (req, res) => {
  const paymentId = req.params.id;
  const userId = req.user.user_id;

  try {
    const [payments] = await db.query(
      `SELECT p.*,
              GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), p.expires_at)) AS remaining_seconds
       FROM payments p
       WHERE p.payment_id = ?`,
      [paymentId]
    );

    if (payments.length === 0) {
      return res.status(404).json({ message: 'Payment record not found.' });
    }

    const payment = payments[0];

    if (payment.buyer_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Forbidden: You do not have permission to view this payment.',
      });
    }

    if (payment.status === 'pending' && payment.remaining_seconds === 0) {
      await db.query(
        'UPDATE payments SET status = "expired" WHERE payment_id = ?',
        [paymentId]
      );
      payment.status = 'expired';
    }

    return res.status(200).json(payment);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};
