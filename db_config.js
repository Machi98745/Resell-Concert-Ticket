const mysql = require("mysql2");

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '', // หากตั้งรหัสผ่านใน XAMPP/MySQL ให้ใส่ตรงนี้
  database: 'concert_ticket_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;