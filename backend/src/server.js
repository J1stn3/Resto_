require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/database');
const routes = require('./routes');

process.on('unhandledRejection', (err) => console.error('Unhandled rejection:', err));

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', message: 'Restaurant POS API is running' });
});

app.use('/api/v1', routes);

app.use((err, req, res, next) => {
  console.error(err);
  if (err.code === 'ECONNREFUSED' || err.code === 'ER_ACCESS_DENIED_ERROR') {
    return res.status(503).json({
      success: false,
      message: 'Database connection failed. Check backend/.env and MySQL service.',
      error: err.message,
    });
  }
  if (err.code?.startsWith?.('ER_')) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Database query failed',
      error: err.code,
    });
  }
  res.status(500).json({ success: false, message: 'Internal server error', error: err.message });
});

app.listen(PORT, async () => {
  console.log(`POS API server running on http://localhost:${PORT}`);
  console.log(`API base: http://localhost:${PORT}/api/v1`);
  try {
    await pool.query('SELECT 1');
    const [ver] = await pool.query('SELECT VERSION() AS v');
    console.log(`MySQL Server connected: ${ver[0].v}`);
    console.log(`Database: ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
  } catch (err) {
    console.error('MySQL Server connection failed:', err.message);
    console.error('Run: .\\scripts\\first-run.ps1  (requires local MySQL Server install)');
  }
});
