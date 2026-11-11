const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, authorizeRoles } = require('../middlewares/authMiddleware');

// ทุก Route ใน /api/admin ต้องเป็น Admin เท่านั้น
router.use(verifyToken, authorizeRoles('admin'));

router.get('/users', adminController.getAllUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.patch('/users/:id/verify', adminController.verifySeller);
router.delete('/users/:id', adminController.deleteUser);

module.exports = router;
