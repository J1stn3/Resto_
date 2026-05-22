const express = require('express');
const { authenticate } = require('../middleware/auth');
const wrap = require('../utils/asyncHandler');

const auth = require('../controllers/authController');
const orders = require('../controllers/orderController');
const products = require('../controllers/productController');
const tables = require('../controllers/tableController');
const payments = require('../controllers/paymentController');
const kitchen = require('../controllers/kitchenController');
const admin = require('../controllers/adminController');

const router = express.Router();

// Public
router.post('/auth/login', wrap(auth.login));
router.post('/auth/register', wrap(auth.register));
router.post('/auth/logout', wrap(auth.logout));

// All routes below require authentication only (admin-only system)
router.get('/auth/me', authenticate, wrap(auth.me));

// Catalog
router.get('/products', authenticate, wrap(products.getProducts));
router.get('/products/:id', authenticate, wrap(products.getProduct));
router.get('/categories', authenticate, wrap(products.getCategories));
router.get('/categories/:id/products', authenticate, wrap(products.getProductsByCategory));

// Tables
router.get('/tables', authenticate, wrap(tables.getTables));
router.get('/tables/by-location', authenticate, wrap(tables.getTablesByLocation));
router.get('/tables/status', authenticate, wrap(tables.getTableStatus));
router.get('/tables/:id', authenticate, wrap(tables.getTable));

// Orders
router.get('/orders', authenticate, wrap(orders.listOrders));
router.post('/orders', authenticate, wrap(orders.createOrder));
router.get('/orders/:id', authenticate, wrap(orders.getOrder));
router.patch('/orders/:id/status', authenticate, wrap(orders.updateStatus));
router.get('/orders/:id/payments', authenticate, wrap(payments.getPayments));
router.get('/orders/:id/payment-summary', authenticate, wrap(payments.getPaymentSummary));
router.post('/orders/:id/payments', authenticate, wrap(payments.processPayment));

// Legacy paths (same handlers — no role checks)
router.post('/server/orders', authenticate, wrap(orders.createOrder));
router.post('/counter/orders', authenticate, wrap(orders.createOrder));
router.post('/counter/orders/:id/payments', authenticate, wrap(payments.processPayment));

// Kitchen
router.get('/kitchen/orders', authenticate, wrap(kitchen.getKitchenOrders));
router.patch('/kitchen/orders/:id/items/:item_id/status', authenticate, wrap(kitchen.updateItemStatus));

// Admin / management (authenticate only)
router.get('/admin/dashboard/stats', authenticate, wrap(admin.dashboardStats));
router.get('/admin/reports/sales', authenticate, wrap(admin.salesReport));
router.get('/admin/reports/orders', authenticate, wrap(admin.ordersReport));
router.get('/admin/reports/income', authenticate, wrap(admin.incomeReport));
router.get('/admin/products', authenticate, wrap(products.getProducts));
router.post('/admin/products', authenticate, wrap(admin.createProduct));
router.put('/admin/products/:id', authenticate, wrap(admin.updateProduct));
router.delete('/admin/products/:id', authenticate, wrap(admin.deleteProduct));
router.get('/admin/categories', authenticate, wrap(admin.listCategories));
router.post('/admin/categories', authenticate, wrap(admin.createCategory));
router.put('/admin/categories/:id', authenticate, wrap(admin.updateCategory));
router.delete('/admin/categories/:id', authenticate, wrap(admin.deleteCategory));
router.get('/admin/tables', authenticate, wrap(admin.listAdminTables));
router.post('/admin/tables', authenticate, wrap(admin.createTable));
router.put('/admin/tables/:id', authenticate, wrap(admin.updateTable));
router.delete('/admin/tables/:id', authenticate, wrap(admin.deleteTable));
router.get('/admin/users', authenticate, wrap(admin.listUsers));
router.post('/admin/users', authenticate, wrap(admin.createUser));
router.put('/admin/users/:id', authenticate, wrap(admin.updateUser));
router.delete('/admin/users/:id', authenticate, wrap(admin.deleteUser));
router.post('/admin/orders', authenticate, wrap(orders.createOrder));
router.post('/admin/orders/:id/payments', authenticate, wrap(payments.processPayment));

module.exports = router;
