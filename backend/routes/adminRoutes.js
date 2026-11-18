const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const adminController = require('../controllers/adminController');
const concertController = require('../controllers/concertController');
const authMiddleware = require('../middlewares/authMiddleware');

// ตั้งค่าโฟลเดอร์เก็บรูปโปสเตอร์
const uploadDir = path.join(__dirname, '../uploads/posters');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `poster_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

// ตรวจสอบ Token และสิทธิ์ Admin
const verifyToken = authMiddleware.verifyToken || authMiddleware;
const checkAdmin =
  authMiddleware.isAdmin ||
  authMiddleware.verifyAdmin ||
  authMiddleware.checkAdmin ||
  ((req, res, next) => {
    if (req.user && String(req.user.role).toLowerCase() === 'admin') {
      return next();
    }
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  });

router.use(verifyToken, checkAdmin);

// Users
router.get('/users', adminController.getAllUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.patch('/users/:id/verify', adminController.verifySeller);
router.delete('/users/:id', adminController.deleteUser);

// อัปโหลดรูปภาพโปสเตอร์คอนเสิร์ต
router.post('/concerts/upload-poster', upload.single('poster'), concertController.uploadPoster);

// Concerts
router.get('/concerts', concertController.getAllConcerts);
router.get('/concerts/:id', concertController.getConcertById);
router.post('/concerts', concertController.createConcert);
router.put('/concerts/:id', concertController.updateConcert);
router.delete('/concerts/:id', concertController.deleteConcert);

module.exports = router;