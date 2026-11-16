
const jwt = require('jsonwebtoken');

// อ่าน Secret จากไฟล์ .env
const JWT_KEY = process.env.JWT_SECRET;

if (!JWT_KEY) {
  throw new Error('JWT_SECRET is not configured in .env');
}

// ตรวจสอบ JWT Token (บังคับต้องล็อกอิน)
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // ต้องส่ง Token ในรูปแบบ Bearer <token>
  const token = authHeader?.startsWith('Bearer ')
    ? authHeader.substring(7)
    : null;

  if (!token) {
    return res.status(401).json({
      message: 'Access denied. No token provided.',
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_KEY);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({
      message: 'Invalid or expired token.',
    });
  }
};

// ตรวจสอบ JWT Token แบบไม่บังคับ
const optionalVerifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  const token = authHeader?.startsWith('Bearer ')
    ? authHeader.substring(7)
    : null;

  if (token) {
    try {
      req.user = jwt.verify(token, JWT_KEY);
    } catch (error) {
      req.user = null;
    }
  }

  next();
};

// ตรวจสอบสิทธิ์ตาม Role
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
