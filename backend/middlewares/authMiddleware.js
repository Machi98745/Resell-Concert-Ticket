const jwt = require('jsonwebtoken');

const JWT_KEY = process.env.JWT_SECRET || 'thisisthesecretforjwt_concert_app';

// ตรวจสอบ JWT Token (บังคับต้องล็อกอิน)
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_KEY);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token.' });
  }
};

// ตรวจสอบ JWT Token แบบไม่บังคับ (ถ้ามีก็แกะให้ ถ้าไม่มีก็ไปต่อได้)
const optionalVerifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token) {
    try {
      req.user = jwt.verify(token, JWT_KEY);
    } catch (_) {
      // ignore invalid optional token
    }
  }
  next();
};

// ตรวจสอบสิทธิ์ตาม Role (เช่น 'admin', 'customer')
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: 'Forbidden: You do not have permission to access this resource.',
      });
    }
    next();
  };
};

module.exports = {
  JWT_KEY,
  verifyToken,
  optionalVerifyToken,
  authorizeRoles,
};
