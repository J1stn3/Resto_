const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');

const TAX_RATE = parseFloat(process.env.TAX_RATE || '0.10');
const VALID_ORDER_STATUSES = ['pending', 'confirmed', 'preparing', 'ready', 'served', 'completed', 'cancelled'];
const VALID_ITEM_STATUSES = ['pending', 'preparing', 'ready', 'served'];

function generateOrderNumber() {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, '');
  const seq = String(Date.now() % 10000).padStart(4, '0');
  return `ORD${date}${seq}`;
}

async function loadOrderItems(conn, orderId) {
  const [rows] = await conn.query(
    `SELECT oi.*, p.name as product_name, p.sku
     FROM order_items oi
     JOIN products p ON oi.product_id = p.id
     WHERE oi.order_id = ?`,
    [orderId]
  );
  return rows;
}

async function getOrderById(orderId, conn = pool) {
  const [orders] = await conn.query(
    `SELECT o.*, t.table_number, t.location, u.name as user_name, u.email as user_email
     FROM orders o
     LEFT JOIN dining_tables t ON o.table_id = t.id
     LEFT JOIN users u ON o.user_id = u.id
     WHERE o.id = ?`,
    [orderId]
  );
  if (!orders.length) return null;
  const order = orders[0];
  if (order.table_number) {
    order.table = { table_number: order.table_number, location: order.location };
  }
  if (order.user_name) {
    order.user = { name: order.user_name, email: order.user_email };
  }
  delete order.table_number;
  delete order.location;
  delete order.user_name;
  delete order.user_email;
  order.items = await loadOrderItems(conn, orderId);
  const [payments] = await conn.query('SELECT * FROM payments WHERE order_id = ?', [orderId]);
  order.payments = payments;
  return order;
}

async function createOrder(userId, body, forcedOrderType = null) {
  const orderType = forcedOrderType || body.order_type;
  if (!body.items?.length) throw Object.assign(new Error('Order must contain at least one item'), { code: 'empty_order' });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    let subtotal = 0;
    const pricedItems = [];
    for (const item of body.items) {
      const [products] = await conn.query(
        'SELECT price FROM products WHERE id = ? AND is_available = TRUE',
        [item.product_id]
      );
      if (!products.length) throw Object.assign(new Error('Product not found or not available'), { code: 'product_not_found' });
      const price = parseFloat(products[0].price);
      subtotal += price * item.quantity;
      pricedItems.push({ ...item, price });
    }

    const taxAmount = subtotal * TAX_RATE;
    const totalAmount = subtotal + taxAmount;
    const orderId = uuidv4();
    const orderNumber = generateOrderNumber();

    const initialStatus = 'confirmed';

    await conn.query(
      `INSERT INTO orders (id, order_number, table_id, user_id, customer_name, order_type, status,
        subtotal, tax_amount, discount_amount, total_amount, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)`,
      [orderId, orderNumber, body.table_id || null, userId, body.customer_name || null,
        orderType, initialStatus, subtotal, taxAmount, totalAmount, body.notes || null]
    );

    await conn.query(
      `INSERT INTO order_status_history (id, order_id, previous_status, new_status, changed_by, notes)
       VALUES (?, ?, NULL, ?, ?, ?)`,
      [uuidv4(), orderId, initialStatus, userId, 'Order placed']
    );

    for (const item of pricedItems) {
      const itemId = uuidv4();
      const totalPrice = item.price * item.quantity;
      await conn.query(
        `INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, total_price, special_instructions)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [itemId, orderId, item.product_id, item.quantity, item.price, totalPrice, item.special_instructions || null]
      );
    }

    if (orderType === 'dine_in' && body.table_id) {
      await conn.query('UPDATE dining_tables SET is_occupied = TRUE WHERE id = ?', [body.table_id]);
    }

    await conn.commit();
    return getOrderById(orderId);
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

async function updateOrderStatus(orderId, userId, status, notes = null) {
  if (!VALID_ORDER_STATUSES.includes(status)) {
    throw Object.assign(new Error('Invalid order status'), { code: 'invalid_status' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [orders] = await conn.query('SELECT status, table_id FROM orders WHERE id = ?', [orderId]);
    if (!orders.length) throw Object.assign(new Error('Order not found'), { code: 'order_not_found' });
    const previousStatus = orders[0].status;
    const tableId = orders[0].table_id;

    let extra = '';
    if (status === 'served') extra = ', served_at = NOW()';
    if (status === 'completed') extra = ', completed_at = NOW()';

    await conn.query(`UPDATE orders SET status = ?${extra} WHERE id = ?`, [status, orderId]);

    await conn.query(
      `INSERT INTO order_status_history (id, order_id, previous_status, new_status, changed_by, notes)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [uuidv4(), orderId, previousStatus, status, userId, notes]
    );

    if (['completed', 'cancelled'].includes(status) && tableId) {
      await conn.query('UPDATE dining_tables SET is_occupied = FALSE WHERE id = ?', [tableId]);
    }

    await conn.commit();
    return getOrderById(orderId);
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

async function updateOrderItemStatus(orderId, itemId, status) {
  if (!VALID_ITEM_STATUSES.includes(status)) {
    throw Object.assign(new Error('Invalid item status'), { code: 'invalid_status' });
  }
  const [result] = await pool.query(
    'UPDATE order_items SET status = ? WHERE id = ? AND order_id = ?',
    [status, itemId, orderId]
  );
  if (result.affectedRows === 0) throw Object.assign(new Error('Order item not found'), { code: 'not_found' });
}

module.exports = {
  TAX_RATE,
  generateOrderNumber,
  getOrderById,
  createOrder,
  updateOrderStatus,
  updateOrderItemStatus,
  loadOrderItems,
  VALID_ORDER_STATUSES,
};
