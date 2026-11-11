const express = require('express');
const router = express.Router();
const resellController = require('../controllers/resellController');
const { verifyToken, optionalVerifyToken } = require('../middlewares/authMiddleware');

// ดึงรายการตั๋วมือสองที่ขายอยู่ (เรียกได้ทั้ง /api/resell/listings และ /api/resell)
router.get('/listings', resellController.getAllResellListings);
router.get('/', resellController.getAllResellListings);

// ดึงรายการตั๋วที่ตัวเองกำลังประกาศขาย (ต้องอยู่ก่อน /:id)
router.get('/my-listings', verifyToken, resellController.getMyResellListings);

// ดูรายละเอียดตั๋วมือสองตาม ID (/api/resell/:id)
router.get('/:id', resellController.getResellListingById);

// สร้างประกาศขายตั๋วมือสอง (เรียกได้ทั้ง /api/resell/create และ /api/resell)
router.post('/create', optionalVerifyToken, resellController.createResellListing);
router.post('/', optionalVerifyToken, resellController.createResellListing);

// ยกเลิกประกาศขายตั๋วมือสอง (/api/resell/:id/cancel)
router.patch('/:id/cancel', verifyToken, resellController.cancelResellListing);

module.exports = router;
