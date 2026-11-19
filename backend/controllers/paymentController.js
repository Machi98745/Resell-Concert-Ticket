
const db = require('../db_config');

const PAYMENT_TIMEOUT_MINUTES = 15;
const COMMISSION_RATE = 0.02;
const PARCEL_SHIPPING_FEE = 50;

// แปลงชื่อช่องทางชำระเงินให้ตรงกับ ENUM ใน Database
function normalizePaymentMethod(rawMethod) {
  if (!rawMethod) return 'promptpay';

  const lower = String(rawMethod).trim().toLowerCase();

  if (lower.includes('credit') || lower.includes('card')) {
    return 'credit_card';
  }

  if (lower.includes('true')) {
    return 'truemoney';
  }

  return 'promptpay';
}

// 1. สร้างรายการสั่งซื้อตั๋ว
// POST /api/payments/create หรือ /api/payments/checkout
exports.createPayment = async (req, res) => {
  const buyerId = req.user.user_id;
  const { listing_id } = req.body;

  const rawDeliveryMethod =
    req.body.delivery_method || req.body.receive_method;

  const shippingInfo =
    req.body.shipping_info || req.body.receive_details;

  const paymentMethod = normalizePaymentMethod(
    req.body.payment_method
  );

  if (!listing_id || !rawDeliveryMethod || !shippingInfo) {
    return res.status(400).json({
      message:
        'Please provide listing_id, delivery_method (or receive_method), and shipping_info (or receive_details).',
    });
  }

  const allowedMethods = [
    'delivery',
    'meetup',
    'Parcel Shipping',
    'Digital Transfer',
  ];

  if (!allowedMethods.includes(rawDeliveryMethod)) {
    return res.status(400).json({
      message:
        'delivery_method must be "delivery", "meetup", "Parcel Shipping", or "Digital Transfer".',
    });
  }

  const isParcel =
    rawDeliveryMethod === 'delivery' ||
    rawDeliveryMethod === 'Parcel Shipping';

  const conn = await db.getConnection();

  try {
    await conn.beginTransaction();

    // ล็อกแถวรายการขาย ป้องกันการจองพร้อมกัน
    const [listings] = await conn.query(
      `SELECT *
       FROM resell_listings
       WHERE listing_id = ?
       FOR UPDATE`,
      [listing_id]
    );

    if (listings.length === 0) {
      await conn.rollback();

      return res.status(404).json({
        message: 'Resell ticket listing not found.',
      });
    }

    const listing = listings[0];

    if (listing.status !== 'available') {
      await conn.rollback();

      return res.status(400).json({
        message: 'This ticket has already been sold or cancelled.',
      });
    }

    if (Number(listing.seller_id) === Number(buyerId)) {
      await conn.rollback();

      return res.status(400).json({
        message: 'You cannot purchase your own resell ticket.',
      });
    }

    // แก้ไข: เปลี่ยนออเดอร์ที่หมดเวลาเป็น expired
    await conn.query(
      `UPDATE payments
       SET status = 'expired',
           shipping_status = 'Expired'
       WHERE listing_id = ?
         AND status = 'pending'
         AND expires_at <= NOW()`,
      [listing_id]
    );

    // ตรวจสอบว่ามีออเดอร์ที่ยังรอชำระเงินหรือไม่
    const [activePayments] = await conn.query(
      `SELECT *,
              GREATEST(
                0,
                TIMESTAMPDIFF(SECOND, NOW(), expires_at)
              ) AS remaining_seconds
       FROM payments
       WHERE listing_id = ?
         AND status = 'pending'
         AND expires_at > NOW()`,
      [listing_id]
    );

    const basePrice = Number(listing.resell_price);
    const commissionFee = Math.round(basePrice * COMMISSION_RATE);
    const shippingFee = isParcel ? PARCEL_SHIPPING_FEE : 0;
    const totalAmount = basePrice + commissionFee + shippingFee;

    if (activePayments.length > 0) {
      // มีผู้ซื้อคนอื่นกำลังจอง
      if (
        Number(activePayments[0].buyer_id) !== Number(buyerId)
      ) {
        await conn.rollback();

        return res.status(409).json({
          message:
            'Another buyer is currently in the payment process for this ticket. Please wait up to 15 minutes.',
        });
      }

      // ผู้ซื้อคนเดิมกดซื้อซ้ำหลังจากเคยมีรายการค้างอยู่
      // รีเซ็ตเวลานับถอยหลังใหม่เต็ม 15 นาที เพื่อไม่ให้นับเวลาต่อจากเดิม
      await conn.query(
        `UPDATE payments
         SET amount = ?, commission_fee = ?, shipping_fee = ?, payment_method = ?, delivery_method = ?, shipping_info = ?, expires_at = DATE_ADD(NOW(), INTERVAL ? MINUTE)
         WHERE payment_id = ?`,
        [
          totalAmount,
          commissionFee,
          shippingFee,
          paymentMethod,
          rawDeliveryMethod,
          String(shippingInfo).trim(),
          PAYMENT_HOLD_MINUTES,
          activePayments[0].payment_id,
        ]
      );

      const [updatedPending] = await conn.query(
        'SELECT *, GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), expires_at)) AS remaining_seconds FROM payments WHERE payment_id = ?',
        [activePayments[0].payment_id]
      );

      await conn.commit();

      return res.status(200).json({
        message:
          'Active order already exists. Please complete payment within the remaining time.',
        payment: {
          ...updatedPending[0],
          receive_method: updatedPending[0].delivery_method,
          receive_details: updatedPending[0].shipping_info,
        },
      });
    }

    // สร้างรายการชำระเงินใหม่
    const [result] = await conn.query(
      `INSERT INTO payments
        (
          listing_id,
          buyer_id,
          amount,
          commission_fee,
          shipping_fee,
          payment_method,
          delivery_method,
          shipping_info,
          shipping_status,
          status,
          expires_at
        )
       VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?,
          'Waiting for payment',
          'pending',
          DATE_ADD(NOW(), INTERVAL ? MINUTE)
       )`,
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

    // ดึงข้อมูลรายการที่สร้างขึ้น
    const [createdRows] = await conn.query(
      `SELECT *,
              GREATEST(
                0,
                TIMESTAMPDIFF(SECOND, NOW(), expires_at)
              ) AS remaining_seconds
       FROM payments
       WHERE payment_id = ?`,
      [result.insertId]
    );

    await conn.commit();

    return res.status(201).json({
      message:
        'Order created successfully. Please complete payment within 15 minutes.',
      payment: {
        ...createdRows[0],
        receive_method: createdRows[0].delivery_method,
        receive_details: createdRows[0].shipping_info,
      },
    });
  } catch (err) {
    await conn.rollback();

    console.error('Create payment error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  } finally {
    conn.release();
  }
};

// 2. ยืนยันการชำระเงินและโอนกรรมสิทธิ์ตั๋ว
// POST /api/payments/:id/confirm
exports.confirmPayment = async (req, res) => {
  const paymentId = req.params.id;
  const buyerId = req.user.user_id;

  const conn = await db.getConnection();

  try {
    await conn.beginTransaction();

    const [payments] = await conn.query(
      `SELECT
          p.*,
          rl.ticket_id,
          rl.status AS listing_status
       FROM payments p
       JOIN resell_listings rl
         ON p.listing_id = rl.listing_id
       WHERE p.payment_id = ?
       FOR UPDATE`,
      [paymentId]
    );

    if (payments.length === 0) {
      await conn.rollback();

      return res.status(404).json({
        message: 'Payment record not found.',
      });
    }

    const payment = payments[0];

    if (Number(payment.buyer_id) !== Number(buyerId)) {
      await conn.rollback();

      return res.status(403).json({
        message:
          'Forbidden: You do not own this payment record.',
      });
    }

    if (
      payment.status === 'completed' ||
      payment.status === 'paid'
    ) {
      await conn.rollback();

      return res.status(400).json({
        message: 'This payment has already been completed.',
      });
    }

    if (payment.status !== 'pending') {
      await conn.rollback();

      return res.status(400).json({
        message:
          `Cannot confirm payment with status "${payment.status}".`,
      });
    }

    // ตรวจสอบเวลาหมดอายุ
    const [timeCheck] = await conn.query(
      'SELECT NOW() >= ? AS is_expired',
      [payment.expires_at]
    );

    if (timeCheck[0].is_expired === 1) {
      await conn.query(
        `UPDATE payments
         SET status = 'expired',
             shipping_status = 'Expired'
         WHERE payment_id = ?`,
        [paymentId]
      );

      await conn.commit();

      return res.status(400).json({
        message:
          'Payment timeout (exceeded 15 minutes). Please create a new order.',
      });
    }

    if (payment.listing_status !== 'available') {
      await conn.rollback();

      return res.status(400).json({
        message: 'This ticket is no longer available.',
      });
    }

    // แก้ไข: ใช้ payment.listing_id แทน listing_id
    // เปลี่ยนรายการที่หมดเวลาแล้วของ Listing นี้เป็น expired
    await conn.query(
      `UPDATE payments
       SET status = 'expired',
           shipping_status = 'Expired'
       WHERE listing_id = ?
         AND status = 'pending'
         AND expires_at <= NOW()`,
      [payment.listing_id]
    );

    // เปลี่ยนสถานะรายการขายเป็น sold
    await conn.query(
      `UPDATE resell_listings
       SET status = 'sold'
       WHERE listing_id = ?`,
      [payment.listing_id]
    );

    // โอนกรรมสิทธิ์ตั๋วให้ผู้ซื้อ
    await conn.query(
      `UPDATE tickets
       SET user_id = ?
       WHERE ticket_id = ?`,
      [buyerId, payment.ticket_id]
    );

    // เปลี่ยนสถานะการชำระเงิน
    await conn.query(
      `UPDATE payments
       SET status = 'completed',
           shipping_status = 'Preparing',
           paid_at = NOW()
       WHERE payment_id = ?`,
      [paymentId]
    );

    await conn.commit();

    return res.status(200).json({
      message:
        'Payment completed and ticket ownership transferred successfully.',
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

    console.error('Confirm payment error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  } finally {
    conn.release();
  }
};

// 3. ยกเลิกคำสั่งซื้อ
// POST /api/payments/:id/cancel
exports.cancelPayment = async (req, res) => {
  const paymentId = req.params.id;
  const buyerId = req.user.user_id;

  try {
    const [payments] = await db.query(
      `SELECT *
       FROM payments
       WHERE payment_id = ?`,
      [paymentId]
    );

    if (payments.length === 0) {
      return res.status(404).json({
        message: 'Payment record not found.',
      });
    }

    const payment = payments[0];

    if (Number(payment.buyer_id) !== Number(buyerId)) {
      return res.status(403).json({
        message:
          'Forbidden: You do not own this payment record.',
      });
    }

    if (
      payment.status === 'completed' ||
      payment.status === 'paid'
    ) {
      return res.status(400).json({
        message: 'Cannot cancel a completed payment.',
      });
    }

    await db.query(
      `UPDATE payments
       SET status = 'cancelled',
           shipping_status = 'Cancelled'
       WHERE payment_id = ?`,
      [paymentId]
    );

    return res.status(200).json({
      message: 'Order cancelled successfully.',
      payment_id: Number(paymentId),
      status: 'cancelled',
    });
  } catch (err) {
    console.error('Cancel payment error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  }
};

// 4. ดึงประวัติคำสั่งซื้อของผู้ใช้ (ทั้งรายการที่ซื้อและรายการที่ขายสำเร็จเพื่อกดส่งบัตร)
// GET /api/payments/my-orders

exports.getMyOrders = async (req, res) => {
  const userId = req.user.user_id;

  try {
    // เปลี่ยนรายการ Pending ที่หมดเวลาเป็น Expired
    await db.query(
      `UPDATE payments
       SET status = 'expired',
           shipping_status = 'Expired'
       WHERE buyer_id = ?
         AND status = 'pending'
         AND expires_at <= NOW()`,
      [userId]
    );

    const sql = `
      SELECT
        p.*,

        GREATEST(
          0,
          TIMESTAMPDIFF(SECOND, NOW(), p.expires_at)
        ) AS remaining_seconds,

        rl.resell_price,
        rl.ticket_id,
        rl.seller_id,

        seller.full_name AS seller_name,
        seller.username AS seller_username,
        seller.email AS seller_email,

        buyer.full_name AS buyer_name,
        buyer.username AS buyer_username,
        buyer.email AS buyer_email,

        CASE WHEN rl.seller_id = ? THEN 1 ELSE 0 END AS is_seller,
        CASE WHEN p.buyer_id = ? THEN 1 ELSE 0 END AS is_buyer,

        t.ticket_id AS actual_ticket_id,

        CASE
          WHEN p.status IN ('completed', 'paid') AND p.buyer_id = ?
          THEN t.ticket_code
          ELSE CONCAT(LEFT(COALESCE(t.ticket_code, ''), 4), '-****')
        END AS ticket_code,

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

      LEFT JOIN resell_listings rl
        ON p.listing_id = rl.listing_id

      LEFT JOIN users seller
        ON rl.seller_id = seller.user_id

      LEFT JOIN users buyer
        ON p.buyer_id = buyer.user_id

      LEFT JOIN tickets t
        ON rl.ticket_id = t.ticket_id

      LEFT JOIN concerts c
        ON t.concert_id = c.concert_id

      WHERE p.buyer_id = ?
         OR (rl.seller_id = ? AND p.status IN ('completed', 'paid'))

      ORDER BY p.payment_id DESC
    `;

    const [orders] = await db.query(sql, [
      userId,
      userId,
      userId,
      userId,
      userId,
    ]);

    return res.status(200).json(orders);

  } catch (err) {
    console.error('Get my orders error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  }
};

// 5. ตรวจสอบสถานะการชำระเงิน
// GET /api/payments/:id
exports.getPaymentById = async (req, res) => {
  const paymentId = req.params.id;
  const userId = req.user.user_id;

  try {
    const [payments] = await db.query(
      `SELECT
          p.*,
          GREATEST(
            0,
            TIMESTAMPDIFF(SECOND, NOW(), p.expires_at)
          ) AS remaining_seconds
       FROM payments p
       WHERE p.payment_id = ?`,
      [paymentId]
    );

    if (payments.length === 0) {
      return res.status(404).json({
        message: 'Payment record not found.',
      });
    }

    const payment = payments[0];

    if (
      Number(payment.buyer_id) !== Number(userId) &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({
        message:
          'Forbidden: You do not have permission to view this payment.',
      });
    }

    if (
      payment.status === 'pending' &&
      Number(payment.remaining_seconds) === 0
    ) {
      await db.query(
        `UPDATE payments
         SET status = 'expired',
             shipping_status = 'Expired'
         WHERE payment_id = ?`,
        [paymentId]
      );

      payment.status = 'expired';
      payment.shipping_status = 'Expired';
    }

    return res.status(200).json(payment);
  } catch (err) {
    console.error('Get payment error:', err);

    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  }
};

// 6. ผู้ขายกดส่งบัตร (POST /api/payments/:id/ship)
exports.shipOrder = async (req, res) => {
  const paymentId = req.params.id;
  const userId = req.user.user_id;
  const rawTracking = req.body?.tracking_number;

  try {
    const [rows] = await db.query(
      `SELECT p.*, rl.seller_id
       FROM payments p
       LEFT JOIN resell_listings rl ON p.listing_id = rl.listing_id
       WHERE p.payment_id = ?`,
      [paymentId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    const order = rows[0];

    if (
      Number(order.seller_id) !== Number(userId) &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({
        message: 'Forbidden: Only the seller of this ticket can mark it as shipped.',
      });
    }

    if (order.status !== 'completed' && order.status !== 'paid') {
      return res.status(400).json({
        message: 'Cannot ship an unpaid order.',
      });
    }

    const trackingNumber =
      rawTracking && String(rawTracking).trim() !== ''
        ? String(rawTracking).trim()
        : `TP-${paymentId}-${Date.now().toString().slice(-6)}`;

    await db.query(
      `UPDATE payments
       SET shipping_status = 'Shipped',
           tracking_number = ?
       WHERE payment_id = ?`,
      [trackingNumber, paymentId]
    );

    return res.status(200).json({
      message: 'Ticket marked as shipped successfully.',
      payment_id: Number(paymentId),
      shipping_status: 'Shipped',
      tracking_number: trackingNumber,
    });
  } catch (err) {
    console.error('Ship order error:', err);
    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  }
};

// 7. ผู้ซื้อกดยืนยันรับบัตร (POST /api/payments/:id/receive)
exports.confirmReceived = async (req, res) => {
  const paymentId = req.params.id;
  const userId = req.user.user_id;

  try {
    const [rows] = await db.query(
      `SELECT p.*, rl.seller_id
       FROM payments p
       LEFT JOIN resell_listings rl ON p.listing_id = rl.listing_id
       WHERE p.payment_id = ?`,
      [paymentId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Order not found.' });
    }

    const order = rows[0];

    if (
      Number(order.buyer_id) !== Number(userId) &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({
        message: 'Forbidden: Only the buyer of this ticket can confirm receipt.',
      });
    }

    if (order.status !== 'completed' && order.status !== 'paid') {
      return res.status(400).json({
        message: 'Cannot confirm receipt of an unpaid order.',
      });
    }

    await db.query(
      `UPDATE payments
       SET shipping_status = 'Delivered'
       WHERE payment_id = ?`,
      [paymentId]
    );

    return res.status(200).json({
      message: 'Ticket receipt confirmed! Order completed.',
      payment_id: Number(paymentId),
      shipping_status: 'Delivered',
      status: 'completed',
    });
  } catch (err) {
    console.error('Confirm received error:', err);
    return res.status(500).json({
      message: 'Database Error',
      error: err.message,
    });
  }
};
