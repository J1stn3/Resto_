/**
 * MySQL Server connection pool (mysql2).
 * This project uses MySQL Server only — no PostgreSQL, SQLite, or Docker DB.
 */
const mysql = require('mysql2/promise');
require('dotenv').config();

const config = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pos_system',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
};

const pool = mysql.createPool(config);

pool.getConnection()
  .then((conn) => {
    conn.release();
  })
  .catch(() => {
    // Startup check is logged in server.js
  });

module.exports = pool;
module.exports.mysqlConfig = config;
