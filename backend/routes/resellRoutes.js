const express = require('express');
const router = express.Router();
const resellController = require('../controllers/resellController');

// ดึงรายการตั๋วมือสองที่ขายอยู่ (เรียกได้ทั้ง /api/resell/listings และ /api/resell)
router.get('/listings', resellController.getAllResellListings);
router.get('/', resellController.getAllResellListings);

// ดูรายละเอียดตั๋วมือสองตาม ID (/api/resell/:id)
router.get('/:id', resellController.getResellListingById);

// สร้างประกาศขายตั๋วมือสอง (เรียกได้ทั้ง /api/resell/create และ /api/resell)
router.post('/create', resellController.createResellListing);
router.post('/', resellController.createResellListing);

module.exports = router;