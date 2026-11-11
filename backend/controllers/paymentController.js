const db = require('../db_config');

const PAYMENT_TIMEOUT_MINUTES = 15;
const COMMISSION_RATE = 0.02;
const PARCEL_SHIPPING_FEE = 50;

// ฟังก์ชันแปลงชื่อช่องทางชำระเงินให้ตรงกับ ENUM('promptpay','credit_card','truemoney') ใน Database
function normalizePaymentMethod(rawMethod) {
  if (!rawMethod) return 'promptpay';
  const lower = String(rawMethod).trim().toLowerCase();
  if (lower.includes('credit') || lower.includes('card')) return 'credit_card';
  if (lower.includes('true')) return 'truemoney';
  return 'promptpay';
}

// 1. สร้างรายการสั่งซื้อตั๋ว + เริ่มจับเวลา 15 นาที (POST /api/payments/create หรือ /checkout)
exports.createPayment = async (req, res) => {
  const buyerId = req.user.user_id;
  const { listing_id } = req.body;
  const rawDeliveryMethod = req.body.delivery_method || req.body.receive_method;
  const shippingInfo = req.body.shipping_info || req.body.receive_details;
  const paymentMethod = normalizePaymentMethod(req.body.payment_method);

  if (!listing_id || !rawDeliveryMethod || !shippingInfo) {
    return res.status(400).json({
      message: 'Please provide listing_id, delivery_method (or receive_method), and shipping_info (or receive_details).',
    });
  }

  const allowedMethods = ['delivery', 'meetup', 'Parcel Shipping', 'Digital Transfer'];
  if (!allowedMethods.includes(rawDeliveryMethod)) {
    return res.status(400).json({
      message: 'delivery_method must be "delivery", "meetup", "Parcel Shipping", or "Digital Transfer".',
    });
  }

  const isParcel = rawDeliveryMethod === 'delivery' || rawDeliveryMethod === 'Parcel Shipping';

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // ล็อกแถว resell_listings ป้องกันการแย่งจองพร้อมกัน (Race Condition)
    const [listings] = await conn.query(
      'SELECT * FROM resell_listings WHERE listing_id = ? FOR UPDATE',
      [listing_id]
    );

    if (listings.length === 0) {
      await conn.rollback();
      return res.status(404).json({ message: 'Resell ticket listing not found.' });
    }

    const listing = listings[0];

    if (listing.status !== 'available') {
      await conn.rollback();
      return res.status(400).json({
        message: 'This ticket has already been sold or cancelled.',
      });
    }

    if (listing.seller_id === buyerId) {
      await conn.rollback();
      return res.status(400).json({
        message: 'You cannot purchase your own resell ticket.',
      });
    }

    // ตัดสถานะออเดอร์เก่าที่หมดเวลาเกิน 15 นาทีแล้วให้เป็น expired
    await conn.query(
      `UPDATE payments
       SET status = 'expired'
       WHERE listing_id = ? AND status = 'pending' AND expires_at <= NOW()`,
      [listing_id]
    );

    // เช็กว่ามีออเดอร์ที่กำลังรอชำระเงิน (ยังไม่ครบ 15 นาที) อยู่หรือไม่
    const [activePayments] = await conn.query(
      `SELECT *, GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), expires_at)) AS remaining_seconds
       FROM payments
       WHERE listing_id = ? AND status = 'pending' AND expires_at > NOW()`,
      [listing_id]
    );

    if (activePayments.length > 0) {
      // ถ้าเป็นคนอื่นจองอยู่ ให้แจ้ง 409 Conflict
      if (activePayments[0].buyer_id !== buyerId) {
        await conn.rollback();
        return res.status(409).json({
          message:
            'Another buyer is currently in the payment process for this ticket. Please wait up to 15 minutes.',
        });
      }
      // ถ้าเป็นผู้ซื้อคนเดิมกดซ้ำ ให้คืนค่าออเดอร์เดิมที่กำลังเดินเวลาอยู่โดยไม่สร้างแถวซ้ำ
      await conn.commit();
      return res.status(200).json({
        message: 'Active order already exists. Please complete payment within the remaining time.',
        payment: {
          ...activePayments[0],
          receive_method: activePayments[0].delivery_method,
          receive_details: activePayments[0].shipping_info,
        },
      });
    }

    const basePrice = Number(listing.resell_price);
    const commissionFee = Math.round(basePrice * COMMISSION_RATE);
    const shippingFee = isParcel ? PARCEL_SHIPPING_FEE : 0;
    const totalAmount = basePrice + commissionFee + shippingFee;

    const [result] = await conn.query(
      `INSERT INTO payments
        (listing_id, buyer_id, amount, commission_fee, shipping_fee, payment_method, delivery_method, shipping_info, shipping_status, status, expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Waiting for payment', 'pending', DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
      [
        listing_id,
        buyerId,
        totalAmount,
        commissionFee,
        shippingFee,
        paymentMethod,
        rawDeliveryMethod,
        String(shippingInfo).trim(),
        PAYMENT_TIMEOUT_MINUTES,
      ]
    );

    const [createdRows] = await conn.query(
      'SELECT *, GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), expires_at)) AS remaining_seconds FROM payments WHERE payment_id = ?',
      [result.insertId]
    );

    await conn.commit();

    return res.status(201).json({
      message: 'Order created successfully. Please complete payment within 15 minutes.',
      payment: {
        ...createdRows[0],
        receive_method: createdRows[0].delivery_method,
        receive_details: createdRows[0].shipping_info,
      },
    });
  } catch (err) {
    await conn.rollback();
    return res.status(500).json({ message: 'Database Error', error: err.message });
  } finally {
    conn.release();
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

    if (payment.status === 'completed' || payment.status === 'paid') {
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
        "UPDATE payments SET status = 'expired', shipping_status = 'Expired' WHERE payment_id = ?",
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

    // อัปเดตสถานะในตาราง payments เป็น 'completed' (ตรงตาม ENUM ของ concert_ticket_db.sql)
    await conn.query(
      "UPDATE payments SET status = 'completed', shipping_status = 'Preparing', paid_at = NOW() WHERE payment_id = ?",
      [paymentId]
    );

    await conn.query(
      "UPDATE resell_listings SET status = 'sold' WHERE listing_id = ?",
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
      delivery_method: payment.delivery_method,
      shipping_info: payment.shipping_info,
      receive_method: payment.delivery_method,
      receive_details: payment.shipping_info,
      status: 'completed',
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

    if (payment.status === 'completed' || payment.status === 'paid') {
      return res.status(400).json({
        message: 'Cannot cancel a completed payment.',
      });
    }

    await db.query(
      "UPDATE payments SET status = 'cancelled', shipping_status = 'Cancelled' WHERE payment_id = ?",
      [paymentId]
    );

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
       SET status = 'expired', shipping_status = 'Expired'
       WHERE buyer_id = ? AND status = 'pending' AND expires_at <= NOW()`,
      [buyerId]
    );

    const sql = `
      SELECT 
        p.*,
        GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), p.expires_at)) AS remaining_seconds,
        rl.resell_price,
        t.ticket_id,
        CASE WHEN p.status = 'completed' THEN t.ticket_code ELSE CONCAT(LEFT(t.ticket_code, 4), '-****') END AS ticket_code,
        t.zone_name,
        t.seat_number,
        c.concert_id,
        c.title AS concert_title,
        c.artist,
        c.category,
        c.venue,
        c.show_datetime,
        c.poster_url
      FROM payments p
      JOIN resell_listings rl ON p.listing_id = rl.listing_id
      JOIN tickets t ON rl.ticket_id = t.ticket_id
      JOIN concerts c ON t.concert_id = c.concert_id
      WHERE p.buyer_id = ?
      ORDER BY p.payment_id DESC
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
        "UPDATE payments SET status = 'expired', shipping_status = 'Expired' WHERE payment_id = ?",
        [paymentId]
      );
      payment.status = 'expired';
    }

    return res.status(200).json(payment);
  } catch (err) {
    return res.status(500).json({ message: 'Database Error', error: err.message });
  }
};
