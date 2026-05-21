const pool = require('../config/database');
const { success, paginated, error } = require('../utils/response');
const { parsePagination, meta } = require('../utils/pagination');

async function getProducts(req, res) {
  const { page, perPage, offset } = parsePagination(req.query);
  const { category_id, available, search } = req.query;
  let where = 'WHERE 1=1';
  const params = [];
  if (category_id) { where += ' AND p.category_id = ?'; params.push(category_id); }
  if (available === 'true') { where += ' AND p.is_available = TRUE'; }
  if (search) { where += ' AND (p.name LIKE ? OR p.sku LIKE ?)'; params.push(`%${search}%`, `%${search}%`); }

  const [countRows] = await pool.query(`SELECT COUNT(*) as total FROM products p ${where}`, params);
  const [rows] = await pool.query(
    `SELECT p.*, c.name as category_name, c.color as category_color
     FROM products p LEFT JOIN categories c ON p.category_id = c.id
     ${where} ORDER BY p.sort_order ASC, p.name ASC LIMIT ? OFFSET ?`,
    [...params, perPage, offset]
  );
  return paginated(res, 'Products retrieved successfully', rows, meta(page, perPage, countRows[0].total));
}

async function getProduct(req, res) {
  const [rows] = await pool.query(
    `SELECT p.*, c.name as category_name FROM products p
     LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?`,
    [req.params.id]
  );
  if (!rows.length) return error(res, 'Product not found', 404);
  return success(res, 'Product retrieved successfully', rows[0]);
}

async function getCategories(req, res) {
  const activeOnly = req.query.active_only === 'true';
  const sql = activeOnly
    ? 'SELECT * FROM categories WHERE is_active = TRUE ORDER BY sort_order ASC, name ASC'
    : 'SELECT * FROM categories ORDER BY sort_order ASC, name ASC';
  const [rows] = await pool.query(sql);
  return success(res, 'Categories retrieved successfully', rows);
}

async function getProductsByCategory(req, res) {
  const availableOnly = req.query.available_only === 'true';
  let sql = 'SELECT * FROM products WHERE category_id = ?';
  if (availableOnly) sql += ' AND is_available = TRUE';
  sql += ' ORDER BY sort_order ASC, name ASC';
  const [rows] = await pool.query(sql, [req.params.id]);
  return success(res, 'Products retrieved successfully', rows);
}

module.exports = { getProducts, getProduct, getCategories, getProductsByCategory };
