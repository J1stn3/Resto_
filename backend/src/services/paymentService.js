const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');
const orderService = require('./orderService');

const VALID_METHODS = ['cash', 'credit_card', 'debit_card', 'digital_wallet'];

async function processPayment(orderId, userId, { payment_method, amount, reference_number }) {
  if (!VALID_METHODS.includes(payment_method)) {
    throw Object.assign(new Error('Invalid payment method'), { code: 'invalid_payment_method' });
  }
  if (!amount || amount <= 0) {
    throw Object.assign(new Error('Payment amount must be greater than zero'), { code: 'invalid_amount' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [orders] = await conn.query('SELECT total_amount, status, table_id FROM orders WHERE id = ?', [orderId]);
    if (!orders.length) throw Object.assign(new Error('Order not found'), { code: 'order_not_found' });

    const { total_amount: orderTotal, status: orderStatus, table_id: tableId } = orders[0];
    if (['cancelled', 'completed'].includes(orderStatus)) {
      throw Object.assign(new Error(`Order cannot be paid - order is ${orderStatus}`), { code: 'invalid_order_status' });
    }

    const [paidRows] = await conn.query(
      `SELECT COALESCE(SUM(amount), 0) as total_paid FROM payments WHERE order_id = ? AND status = 'completed'`,
      [orderId]
    );
    const totalPaid = parseFloat(paidRows[0].total_paid);
    if (totalPaid >= parseFloat(orderTotal)) {
      throw Object.assign(new Error('Order is already fully paid'), { code: 'order_fully_paid' });
    }
    if (totalPaid + amount > parseFloat(orderTotal) + 0.01) {
      throw Object.assign(new Error('Payment exceeds order total'), { code: 'overpayment' });
    }

    const paymentId = uuidv4();
    await conn.query(
      `INSERT INTO payments (id, order_id, payment_method, amount, reference_number, status, processed_by, processed_at)
       VALUES (?, ?, ?, ?, ?, 'completed', ?, NOW())`,
      [paymentId, orderId, payment_method, amount, reference_number || null, userId]
    );

    const newTotalPaid = totalPaid + amount;
    if (newTotalPaid >= parseFloat(orderTotal) - 0.01) {
      await conn.query(`UPDATE orders SET status = 'completed', completed_at = NOW() WHERE id = ?`, [orderId]);
      if (tableId) await conn.query('UPDATE dining_tables SET is_occupied = FALSE WHERE id = ?', [tableId]);
      await conn.query(
        `INSERT INTO order_status_history (id, order_id, previous_status, new_status, changed_by, notes)
         VALUES (?, ?, ?, 'completed', ?, 'Payment completed')`,
        [uuidv4(), orderId, orderStatus, userId]
      );
    }

    await conn.commit();
    const [payments] = await pool.query('SELECT * FROM payments WHERE id = ?', [paymentId]);
    return payments[0];
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

async function getPaymentSummary(orderId) {
  const [orders] = await pool.query('SELECT total_amount FROM orders WHERE id = ?', [orderId]);
  if (!orders.length) throw Object.assign(new Error('Order not found'), { code: 'order_not_found' });
  const total = parseFloat(orders[0].total_amount);
  const [paidRows] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) as paid FROM payments WHERE order_id = ? AND status = 'completed'`,
    [orderId]
  );
  const paid = parseFloat(paidRows[0].paid);
  return { total_amount: total, paid_amount: paid, remaining_amount: Math.max(0, total - paid), is_fully_paid: paid >= total - 0.01 };
}

module.exports = { processPayment, getPaymentSummary, VALID_METHODS };
