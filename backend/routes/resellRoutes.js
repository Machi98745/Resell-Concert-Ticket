const express = require('express');
const router = express.Router();
const resellController = require('../controllers/resellController');
const { verifyToken } = require('../middlewares/authMiddleware');

// ตรวจสอบว่าฟังก์ชันทั้งหมดใน resellController ครบถ้วนหรือไม่
const requiredHandlers = [
  'getAllResellListings',
  'getMyResellListings',
  'getMyTickets',
  'registerSeller',
  'getSellerStatus',
  'getResellListingById',
  'createResellListing',
  'cancelResellListing',
  'updateResellListing',
  'deleteResellListing',
];

for (const handler of requiredHandlers) {
  if (typeof resellController[handler] !== 'function') {
    throw new Error(
      `resellController.${handler} is missing or is not a function.`
    );
  }
}

if (typeof verifyToken !== 'function') {
  throw new Error('verifyToken middleware is not a function.');
}

// ดึงรายการตั๋วมือสองที่ขายอยู่ (เรียกได้ทั้ง /api/resell/listings และ /api/resell)
router.get('/listings', resellController.getAllResellListings);
router.get('/', resellController.getAllResellListings);

// ดึงรายการตั๋วที่ตัวเองกำลังประกาศขาย (ต้องอยู่ก่อน /:id)
router.get('/my-listings', verifyToken, resellController.getMyResellListings);

// ดึงรายการตั๋วที่เป็นเจ้าของ (/api/resell/my-tickets)
router.get('/my-tickets', verifyToken, resellController.getMyTickets);

// ยืนยันตัวตนผู้ขาย (/api/resell/seller/*)
router.post('/seller/register', verifyToken, resellController.registerSeller);
router.get('/seller/status', verifyToken, resellController.getSellerStatus);

// ดูรายละเอียดตั๋วมือสองตาม ID (/api/resell/:id)
router.get('/:id', resellController.getResellListingById);

// สร้างประกาศขายตั๋วมือสอง (บังคับ verifyToken ป้องกันการสวมรอยลงขายตั๋วคนอื่น)
router.post('/create', verifyToken, resellController.createResellListing);
router.post('/', verifyToken, resellController.createResellListing);

// ยกเลิกประกาศขายตั๋วมือสอง (/api/resell/:id/cancel)
router.patch('/:id/cancel', verifyToken, resellController.cancelResellListing);

// Seller edits / deletes own listing (/api/resell/:id)
router.put('/:id', verifyToken, resellController.updateResellListing);
router.delete('/:id', verifyToken, resellController.deleteResellListing);

module.exports = router;