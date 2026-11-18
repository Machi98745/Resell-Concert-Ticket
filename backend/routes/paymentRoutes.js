const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middlewares/authMiddleware');

// ทุก Route ใน /api/payments ต้องล็อกอินก่อน
router.use(verifyToken);

router.post('/create', paymentController.createPayment);
router.post('/checkout', paymentController.createPayment);
router.post('/:id/confirm', paymentController.confirmPayment);
router.post('/:id/cancel', paymentController.cancelPayment);
router.post('/:id/ship', paymentController.shipOrder);
router.post('/:id/receive', paymentController.confirmReceived);

// ต้องวาง /my-orders ก่อน /:id
router.get('/my-orders', paymentController.getMyOrders);
router.get('/:id', paymentController.getPaymentById);

module.exports = router;
