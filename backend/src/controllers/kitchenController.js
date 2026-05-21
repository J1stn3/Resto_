const pool = require('../config/database');
const orderService = require('../services/orderService');
const { success, error } = require('../utils/response');

async function getKitchenOrders(req, res) {
  const statusFilter = req.query.status;
  let where = `WHERE o.status IN ('confirmed', 'preparing', 'ready')`;
  const params = [];
  if (statusFilter && statusFilter !== 'all') {
    where += ' AND o.status = ?';
    params.push(statusFilter);
  }

  const [rows] = await pool.query(
    `SELECT o.id, o.order_number, o.table_id, o.order_type, o.status, o.created_at,
            o.customer_name, o.notes, t.table_number
     FROM orders o
     LEFT JOIN dining_tables t ON o.table_id = t.id
     ${where} ORDER BY o.created_at ASC`,
    params
  );

  for (const order of rows) {
    order.items = await orderService.loadOrderItems(pool, order.id);
  }

  return success(res, 'Kitchen orders retrieved successfully', rows);
}

async function updateItemStatus(req, res) {
  try {
    await orderService.updateOrderItemStatus(req.params.id, req.params.item_id, req.body.status);
    return success(res, 'Order item status updated successfully');
  } catch (e) {
    return error(res, e.message, e.code === 'not_found' ? 404 : 400, e.code);
  }
}

module.exports = { getKitchenOrders, updateItemStatus };
