const pool = require('../config/database');
const paymentService = require('../services/paymentService');
const { success, error } = require('../utils/response');

async function processPayment(req, res) {
  try {
    const payment = await paymentService.processPayment(req.params.id, req.user.id, req.body);
    return success(res, 'Payment processed successfully', payment, 201);
  } catch (e) {
    const statusMap = { order_not_found: 404, invalid_order_status: 400, order_fully_paid: 400, invalid_amount: 400, invalid_payment_method: 400, overpayment: 400 };
    return error(res, e.message, statusMap[e.code] || 500, e.code);
  }
}

async function getPayments(req, res) {
  const [rows] = await pool.query('SELECT * FROM payments WHERE order_id = ? ORDER BY created_at DESC', [req.params.id]);
  return success(res, 'Payments retrieved successfully', rows);
}

async function getPaymentSummary(req, res) {
  try {
    const summary = await paymentService.getPaymentSummary(req.params.id);
    return success(res, 'Payment summary retrieved successfully', summary);
  } catch (e) {
    return error(res, e.message, e.code === 'order_not_found' ? 404 : 500, e.code);
  }
}

module.exports = { processPayment, getPayments, getPaymentSummary };
