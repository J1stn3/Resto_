const pool = require('../config/database');
const orderService = require('../services/orderService');
const { success, paginated, error } = require('../utils/response');
const { parsePagination, meta } = require('../utils/pagination');

async function listOrders(req, res) {
  const { page, perPage, offset } = parsePagination(req.query);
  const { status, order_type } = req.query;
  let where = 'WHERE 1=1';
  const params = [];
  if (status) { where += ' AND o.status = ?'; params.push(status); }
  if (order_type) { where += ' AND o.order_type = ?'; params.push(order_type); }

  const [countRows] = await pool.query(`SELECT COUNT(*) as total FROM orders o ${where}`, params);
  const total = countRows[0].total;

  const [rows] = await pool.query(
    `SELECT o.*, t.table_number, t.location, u.name as user_name, u.email as user_email
     FROM orders o
     LEFT JOIN dining_tables t ON o.table_id = t.id
     LEFT JOIN users u ON o.user_id = u.id
     ${where} ORDER BY o.created_at DESC LIMIT ? OFFSET ?`,
    [...params, perPage, offset]
  );

  for (const order of rows) {
    order.items = await orderService.loadOrderItems(pool, order.id);
  }

  return paginated(res, 'Orders retrieved successfully', rows, meta(page, perPage, total));
}

async function getOrder(req, res) {
  const order = await orderService.getOrderById(req.params.id);
  if (!order) return error(res, 'Order not found', 404, 'order_not_found');
  return success(res, 'Order retrieved successfully', order);
}

async function createOrder(req, res) {
  try {
    const order = await orderService.createOrder(req.user.id, req.body);
    return success(res, 'Order created successfully', order, 201);
  } catch (e) {
    const code = e.code || 'server_error';
    const status = code === 'empty_order' || code === 'product_not_found' ? 400 : 500;
    return error(res, e.message, status, code);
  }
}

async function updateStatus(req, res) {
  try {
    const order = await orderService.updateOrderStatus(
      req.params.id, req.user.id, req.body.status, req.body.notes
    );
    return success(res, 'Order status updated successfully', order);
  } catch (e) {
    const status = e.code === 'order_not_found' ? 404 : e.code === 'invalid_status' ? 400 : 500;
    return error(res, e.message, status, e.code);
  }
}

module.exports = { listOrders, getOrder, createOrder, updateStatus };
