// src/routes/managerRoutes.js
const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');

// Import controllers
const managerController = require('../controllers/managerController');
const customerController = require('../controllers/customerController');
const expenseController = require('../controllers/expenseController');
const notificationController = require('../controllers/notificationController');

const router = express.Router();

// All manager routes require authentication and manager role
router.use(authenticate);
router.use(authorize('manager'));

// ── Validation helper ──────────────────────────────────────────
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed.',
            errors: errors.array().map(e => ({ field: e.path, message: e.msg }))
        });
    }
    next();
};

// ══════════════════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════════════════

router.get('/dashboard', managerController.getManagerDashboard);
router.get('/alerts', managerController.getAlerts);
router.get('/analytics/sales', managerController.getSalesAnalytics);
router.get('/quick-stats', managerController.getQuickStats);

// ══════════════════════════════════════════════════════════════
// CUSTOMERS
// ══════════════════════════════════════════════════════════════

router.get('/customers', customerController.getCustomers);
router.get('/customers/search', [
    query('phone').notEmpty().withMessage('Phone number is required')
], validate, customerController.searchCustomerByPhone);

router.get('/customers/:id', [
    param('id').isInt({ min: 1 }).withMessage('Invalid customer ID')
], validate, customerController.getCustomerById);

router.get('/customers/:id/transactions', [
    param('id').isInt({ min: 1 }).withMessage('Invalid customer ID')
], validate, customerController.getCustomerTransactions);

router.post('/customers', [
    body('name').notEmpty().withMessage('Name is required'),
    body('phone').notEmpty().withMessage('Phone is required'),
    body('email').optional().isEmail().withMessage('Invalid email')
], validate, customerController.createCustomer);

router.put('/customers/:id', [
    param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
    body('name').optional().notEmpty().withMessage('Name cannot be empty'),
    body('phone').optional().notEmpty().withMessage('Phone cannot be empty'),
    body('email').optional().isEmail().withMessage('Invalid email')
], validate, customerController.updateCustomer);

router.put('/customers/:id/points', [
    param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
    body('points').isInt().withMessage('Points must be an integer')
], validate, customerController.adjustCustomerPoints);

router.post('/customers/:id/redeem', [
    param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
    body('points').isInt({ min: 1 }).withMessage('Points must be a positive integer')
], validate, customerController.redeemCustomerPoints);

// ══════════════════════════════════════════════════════════════
// EXPENSES
// ══════════════════════════════════════════════════════════════

router.get('/expenses', expenseController.getExpenses);
router.get('/expenses/categories', expenseController.getExpenseCategories);

router.post('/expenses', [
    body('category').isIn(['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                           'rent', 'supplies', 'marketing', 'insurance', 'other'])
        .withMessage('Invalid category'),
    body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0'),
    body('description').notEmpty().withMessage('Description is required')
], validate, expenseController.createExpense);

router.put('/expenses/:id', [
    param('id').isInt({ min: 1 }).withMessage('Invalid expense ID'),
    body('category').optional().isIn(['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                                      'rent', 'supplies', 'marketing', 'insurance', 'other'])
        .withMessage('Invalid category'),
    body('amount').optional().isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0')
], validate, expenseController.updateExpense);

router.delete('/expenses/:id', [
    param('id').isInt({ min: 1 }).withMessage('Invalid expense ID')
], validate, expenseController.deleteExpense);

// ══════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ══════════════════════════════════════════════════════════════

router.get('/notifications', notificationController.getNotifications);

router.post('/notifications', [
    body('title').notEmpty().withMessage('Title is required'),
    body('message').notEmpty().withMessage('Message is required'),
    body('target_roles').optional().isArray().withMessage('target_roles must be an array'),
    body('priority').optional().isIn(['low', 'normal', 'high', 'urgent']).withMessage('Invalid priority')
], validate, notificationController.sendNotification);

router.put('/notifications/:id/read', [
    param('id').isInt({ min: 1 }).withMessage('Invalid notification ID')
], validate, notificationController.markNotificationRead);

module.exports = router;