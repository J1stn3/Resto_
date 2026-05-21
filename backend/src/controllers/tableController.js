const pool = require('../config/database');
const { success, error } = require('../utils/response');

async function getTables(req, res) {
  const { location, occupied_only, available_only } = req.query;
  let where = 'WHERE 1=1';
  const params = [];
  if (location) { where += ' AND t.location LIKE ?'; params.push(`%${location}%`); }
  if (occupied_only === 'true') where += ' AND t.is_occupied = TRUE';
  if (available_only === 'true') where += ' AND t.is_occupied = FALSE';

  const [rows] = await pool.query(
    `SELECT t.*, o.id as current_order_id, o.order_number, o.status as order_status,
            o.customer_name, o.total_amount as order_total
     FROM dining_tables t
     LEFT JOIN orders o ON t.id = o.table_id AND o.status NOT IN ('completed', 'cancelled')
     ${where} ORDER BY t.table_number ASC`,
    params
  );
  return success(res, 'Tables retrieved successfully', rows);
}

async function getTable(req, res) {
  const [rows] = await pool.query(
    `SELECT t.*, o.id as current_order_id, o.order_number, o.status as order_status
     FROM dining_tables t
     LEFT JOIN orders o ON t.id = o.table_id AND o.status NOT IN ('completed', 'cancelled')
     WHERE t.id = ?`,
    [req.params.id]
  );
  if (!rows.length) return error(res, 'Table not found', 404);
  return success(res, 'Table retrieved successfully', rows[0]);
}

async function getTablesByLocation(req, res) {
  const [rows] = await pool.query(
    `SELECT t.*, o.id as current_order_id, o.order_number, o.status as order_status
     FROM dining_tables t
     LEFT JOIN orders o ON t.id = o.table_id AND o.status NOT IN ('completed', 'cancelled')
     ORDER BY t.location, t.table_number`
  );
  const grouped = {};
  for (const row of rows) {
    const loc = row.location || 'Unknown';
    if (!grouped[loc]) grouped[loc] = [];
    grouped[loc].push(row);
  }
  return success(res, 'Tables by location retrieved successfully', grouped);
}

async function getTableStatus(req, res) {
  const [rows] = await pool.query(
    `SELECT location,
            COUNT(*) as total_tables,
            SUM(CASE WHEN is_occupied THEN 1 ELSE 0 END) as occupied,
            SUM(CASE WHEN NOT is_occupied THEN 1 ELSE 0 END) as available
     FROM dining_tables GROUP BY location ORDER BY location`
  );
  const [totals] = await pool.query(
    `SELECT COUNT(*) as total, SUM(is_occupied) as occupied FROM dining_tables`
  );
  return success(res, 'Table status retrieved successfully', {
    locations: rows,
    total_tables: totals[0].total,
    occupied_tables: totals[0].occupied || 0,
    available_tables: totals[0].total - (totals[0].occupied || 0),
  });
}

module.exports = { getTables, getTable, getTablesByLocation, getTableStatus };
