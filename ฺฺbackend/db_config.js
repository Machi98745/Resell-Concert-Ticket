const mysql = require("mysql2");

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '', // ใส่รหัสผ่าน XAMPP ถ้ามี
  database: 'concert_ticket_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;