const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');
const { success, paginated, error } = require('../utils/response');
const { parsePagination, meta } = require('../utils/pagination');

async function dashboardStats(req, res) {
  const [[todayOrders]] = await pool.query(
    `SELECT COUNT(*) as c FROM orders WHERE DATE(created_at) = CURDATE()`
  );
  const [[todayRevenue]] = await pool.query(
    `SELECT COALESCE(SUM(total_amount), 0) as r FROM orders WHERE DATE(created_at) = CURDATE() AND status = 'completed'`
  );
  const [[activeOrders]] = await pool.query(
    `SELECT COUNT(*) as c FROM orders WHERE status NOT IN ('completed', 'cancelled')`
  );
  const [[occupiedTables]] = await pool.query(
    `SELECT COUNT(*) as c FROM dining_tables WHERE is_occupied = TRUE`
  );
  const [[totalTables]] = await pool.query(`SELECT COUNT(*) as c FROM dining_tables`);
  const [[totalSeats]] = await pool.query(`SELECT COALESCE(SUM(seating_capacity), 0) as s FROM dining_tables`);
  const total = totalTables.c;
  const occupied = occupiedTables.c;
  return success(res, 'Dashboard stats retrieved successfully', {
    today_orders: todayOrders.c,
    today_revenue: parseFloat(todayRevenue.r),
    active_orders: activeOrders.c,
    total_tables: total,
    occupied_tables: occupied,
    available_tables: total - occupied,
    total_seats: totalSeats.s,
  });
}

async function salesReport(req, res) {
  const period = req.query.period || 'today';
  let sql;
  if (period === 'week') {
    sql = `SELECT DATE(created_at) as date, COUNT(*) as order_count, SUM(total_amount) as revenue
           FROM orders WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND status = 'completed'
           GROUP BY DATE(created_at) ORDER BY date DESC`;
  } else if (period === 'month') {
    sql = `SELECT DATE(created_at) as date, COUNT(*) as order_count, SUM(total_amount) as revenue
           FROM orders WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND status = 'completed'
           GROUP BY DATE(created_at) ORDER BY date DESC`;
  } else {
    sql = `SELECT DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') as date, COUNT(*) as order_count, SUM(total_amount) as revenue
           FROM orders WHERE DATE(created_at) = CURDATE() AND status = 'completed'
           GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') ORDER BY date DESC`;
  }
  const [rows] = await pool.query(sql);
  return success(res, 'Sales report retrieved successfully', rows);
}

async function ordersReport(req, res) {
  const [rows] = await pool.query(
    `SELECT status, COUNT(*) as count, AVG(total_amount) as avg_amount
     FROM orders WHERE DATE(created_at) = CURDATE() GROUP BY status`
  );
  return success(res, 'Orders report retrieved successfully', rows);
}

async function incomeReport(req, res) {
  const period = req.query.period || 'today';
  let groupExpr;
  if (period === 'year') {
    groupExpr = `DATE_FORMAT(created_at, '%Y-%m')`;
  } else if (period === 'today') {
    groupExpr = `DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00')`;
  } else {
    groupExpr = `DATE(created_at)`;
  }
  let dateFilter = `DATE(created_at) = CURDATE()`;
  if (period === 'week') dateFilter = `created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)`;
  if (period === 'month') dateFilter = `created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)`;
  if (period === 'year') dateFilter = `created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)`;

  const [rows] = await pool.query(
    `SELECT ${groupExpr} as period, COUNT(*) as total_orders,
            SUM(total_amount) as gross_income, SUM(tax_amount) as tax_collected,
            SUM(total_amount - tax_amount) as net_income
     FROM orders WHERE ${dateFilter} AND status = 'completed'
     GROUP BY ${groupExpr} ORDER BY period DESC`
  );

  const summary = rows.reduce(
    (acc, r) => ({
      total_orders: acc.total_orders + r.total_orders,
      gross_income: acc.gross_income + parseFloat(r.gross_income || 0),
      tax_collected: acc.tax_collected + parseFloat(r.tax_collected || 0),
      net_income: acc.net_income + parseFloat(r.net_income || 0),
    }),
    { total_orders: 0, gross_income: 0, tax_collected: 0, net_income: 0 }
  );

  return success(res, 'Income report retrieved successfully', { summary, breakdown: rows, period });
}

// --- Users CRUD ---
async function listUsers(req, res) {
  const { page, perPage, offset } = parsePagination(req.query);
  let where = 'WHERE 1=1';
  const params = [];
  if (req.query.active !== undefined) { where += ' AND is_active = ?'; params.push(req.query.active === 'true'); }
  if (req.query.search) {
    where += ' AND (name LIKE ? OR email LIKE ?)';
    const s = `%${req.query.search}%`;
    params.push(s, s);
  }
  const [countRows] = await pool.query(`SELECT COUNT(*) as total FROM users ${where}`, params);
  const [rows] = await pool.query(
    `SELECT id, name, email, is_admin, is_active, created_at
     FROM users ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
    [...params, perPage, offset]
  );
  return paginated(res, 'Users retrieved successfully', rows, meta(page, perPage, countRows[0].total));
}

async function createUser(req, res) {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return error(res, 'Name, email, and password are required', 400, 'validation_error');
  }
  const hash = await bcrypt.hash(password, 10);
  const id = uuidv4();
  await pool.query(
    `INSERT INTO users (id, name, email, password_hash, is_admin) VALUES (?,?,?,?,TRUE)`,
    [id, name, email.toLowerCase(), hash]
  );
  return success(res, 'User created successfully', { id }, 201);
}

async function updateUser(req, res) {
  const fields = [];
  const params = [];
  const allowed = ['name', 'email', 'is_active'];
  for (const f of allowed) {
    if (req.body[f] !== undefined) { fields.push(`${f} = ?`); params.push(req.body[f]); }
  }
  if (req.body.password) {
    fields.push('password_hash = ?');
    params.push(await bcrypt.hash(req.body.password, 10));
  }
  if (!fields.length) return error(res, 'No fields to update', 400);
  params.push(req.params.id);
  const [result] = await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, params);
  if (!result.affectedRows) return error(res, 'User not found', 404);
  return success(res, 'User updated successfully');
}

async function deleteUser(req, res) {
  const [[{ c }]] = await pool.query('SELECT COUNT(*) as c FROM orders WHERE user_id = ?', [req.params.id]);
  if (c > 0) return error(res, 'Cannot delete user with existing orders', 400, 'user_has_orders');
  const [result] = await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);
  if (!result.affectedRows) return error(res, 'User not found', 404);
  return success(res, 'User deleted successfully');
}

// --- Categories CRUD ---
async function listCategories(req, res) {
  const { page, perPage, offset } = parsePagination(req.query);
  let where = 'WHERE 1=1';
  const params = [];
  if (req.query.active_only === 'true') where += ' AND is_active = TRUE';
  if (req.query.search) { where += ' AND (name LIKE ? OR description LIKE ?)'; params.push(`%${req.query.search}%`, `%${req.query.search}%`); }
  const [countRows] = await pool.query(`SELECT COUNT(*) as total FROM categories ${where}`, params);
  const [rows] = await pool.query(
    `SELECT * FROM categories ${where} ORDER BY sort_order ASC, name ASC LIMIT ? OFFSET ?`,
    [...params, perPage, offset]
  );
  return paginated(res, 'Categories retrieved successfully', rows, meta(page, perPage, countRows[0].total));
}

async function createCategory(req, res) {
  const id = uuidv4();
  const { name, description, color, sort_order = 0 } = req.body;
  await pool.query(
    'INSERT INTO categories (id, name, description, color, sort_order) VALUES (?,?,?,?,?)',
    [id, name, description, color, sort_order]
  );
  return success(res, 'Category created successfully', { id }, 201);
}

async function updateCategory(req, res) {
  const fields = [];
  const params = [];
  for (const f of ['name', 'description', 'color', 'sort_order', 'is_active']) {
    if (req.body[f] !== undefined) { fields.push(`${f} = ?`); params.push(req.body[f]); }
  }
  if (!fields.length) return error(res, 'No fields to update', 400);
  params.push(req.params.id);
  const [result] = await pool.query(`UPDATE categories SET ${fields.join(', ')} WHERE id = ?`, params);
  if (!result.affectedRows) return error(res, 'Category not found', 404);
  return success(res, 'Category updated successfully');
}

async function deleteCategory(req, res) {
  const [[{ c }]] = await pool.query('SELECT COUNT(*) as c FROM products WHERE category_id = ?', [req.params.id]);
  if (c > 0) return error(res, 'Cannot delete category with existing products', 400, 'category_has_products');
  const [result] = await pool.query('DELETE FROM categories WHERE id = ?', [req.params.id]);
  if (!result.affectedRows) return error(res, 'Category not found', 404);
  return success(res, 'Category deleted successfully');
}

// --- Products CRUD ---
async function createProduct(req, res) {
  const id = uuidv4();
  const { category_id, name, description, price, image_url, barcode, sku, preparation_time = 0, sort_order = 0 } = req.body;
  await pool.query(
    `INSERT INTO products (id, category_id, name, description, price, image_url, barcode, sku, preparation_time, sort_order)
     VALUES (?,?,?,?,?,?,?,?,?,?)`,
    [id, category_id, name, description, price, image_url, barcode, sku, preparation_time, sort_order]
  );
  return success(res, 'Product created successfully', { id }, 201);
}

async function updateProduct(req, res) {
  const fields = [];
  const params = [];
  for (const f of ['category_id', 'name', 'description', 'price', 'image_url', 'barcode', 'sku', 'is_available', 'preparation_time', 'sort_order']) {
    if (req.body[f] !== undefined) { fields.push(`${f} = ?`); params.push(req.body[f]); }
  }
  if (!fields.length) return error(res, 'No fields to update', 400);
  params.push(req.params.id);
  const [result] = await pool.query(`UPDATE products SET ${fields.join(', ')} WHERE id = ?`, params);
  if (!result.affectedRows) return error(res, 'Product not found', 404);
  return success(res, 'Product updated successfully');
}

async function deleteProduct(req, res) {
  const [[{ c }]] = await pool.query(
    `SELECT COUNT(*) as c FROM order_items oi JOIN orders o ON oi.order_id = o.id
     WHERE oi.product_id = ? AND o.status NOT IN ('completed', 'cancelled')`,
    [req.params.id]
  );
  if (c > 0) return error(res, 'Cannot delete product with active orders', 400, 'product_has_active_orders');
  const [result] = await pool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
  if (!result.affectedRows) return error(res, 'Product not found', 404);
  return success(res, 'Product deleted successfully');
}

// --- Tables CRUD ---
async function listAdminTables(req, res) {
  const { page, perPage, offset } = parsePagination(req.query, 20);
  let where = 'WHERE 1=1';
  const params = [];
  if (req.query.location) { where += ' AND t.location LIKE ?'; params.push(`%${req.query.location}%`); }
  if (req.query.status === 'occupied') where += ' AND t.is_occupied = TRUE';
  if (req.query.status === 'available') where += ' AND t.is_occupied = FALSE';
  if (req.query.search) {
    where += ' AND (t.table_number LIKE ? OR t.table_name LIKE ? OR t.location LIKE ?)';
    params.push(`%${req.query.search}%`, `%${req.query.search}%`, `%${req.query.search}%`);
  }

  const baseFrom = `FROM dining_tables t
    LEFT JOIN orders o ON t.id = o.table_id AND o.status NOT IN ('completed', 'cancelled')`;
  const [countRows] = await pool.query(`SELECT COUNT(DISTINCT t.id) as total ${baseFrom} ${where}`, params);
  const [rows] = await pool.query(
    `SELECT t.*, o.id as order_id, o.order_number, o.customer_name, o.status as order_status,
            o.created_at as order_created_at, o.total_amount
     ${baseFrom} ${where} ORDER BY t.table_number ASC LIMIT ? OFFSET ?`,
    [...params, perPage, offset]
  );
  const data = rows.map((r) => ({
    id: r.id, table_number: r.table_number, table_name: r.table_name,
    seating_capacity: r.seating_capacity,
    location: r.location, is_occupied: !!r.is_occupied, created_at: r.created_at, updated_at: r.updated_at,
    current_order: r.order_id ? {
      id: r.order_id, order_number: r.order_number, customer_name: r.customer_name,
      status: r.order_status, created_at: r.order_created_at, total_amount: r.total_amount,
    } : null,
  }));
  return paginated(res, 'Tables retrieved successfully', data, meta(page, perPage, countRows[0].total));
}

async function createTable(req, res) {
  const id = uuidv4();
  const { table_number, table_name, seating_capacity = 4, location } = req.body;
  const name = table_name?.trim() || `Table ${table_number}`;
  await pool.query(
    'INSERT INTO dining_tables (id, table_number, table_name, seating_capacity, location) VALUES (?,?,?,?,?)',
    [id, table_number, name, seating_capacity, location]
  );
  return success(res, 'Table created successfully', { id }, 201);
}

async function updateTable(req, res) {
  const fields = [];
  const params = [];
  for (const f of ['table_number', 'table_name', 'seating_capacity', 'location', 'is_occupied']) {
    if (req.body[f] !== undefined) { fields.push(`${f} = ?`); params.push(req.body[f]); }
  }
  if (!fields.length) return error(res, 'No fields to update', 400);
  params.push(req.params.id);
  const [result] = await pool.query(`UPDATE dining_tables SET ${fields.join(', ')} WHERE id = ?`, params);
  if (!result.affectedRows) return error(res, 'Table not found', 404);
  return success(res, 'Table updated successfully');
}

async function deleteTable(req, res) {
  const [[{ c }]] = await pool.query(
    `SELECT COUNT(*) as c FROM orders WHERE table_id = ? AND status NOT IN ('completed', 'cancelled')`,
    [req.params.id]
  );
  if (c > 0) return error(res, 'Cannot delete table with active orders', 400, 'table_has_active_orders');
  const [result] = await pool.query('DELETE FROM dining_tables WHERE id = ?', [req.params.id]);
  if (!result.affectedRows) return error(res, 'Table not found', 404);
  return success(res, 'Table deleted successfully');
}

module.exports = {
  dashboardStats, salesReport, ordersReport, incomeReport,
  listUsers, createUser, updateUser, deleteUser,
  listCategories, createCategory, updateCategory, deleteCategory,
  createProduct, updateProduct, deleteProduct,
  listAdminTables, createTable, updateTable, deleteTable,
};
