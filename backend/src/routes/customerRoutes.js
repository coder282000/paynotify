// src/routes/customerRoutes.js
const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');
const {
    getCustomers,
    searchCustomerByPhone,
    getCustomerById,
    getCustomerTransactions,
    createCustomer,
    updateCustomer,
    adjustCustomerPoints,
    redeemCustomerPoints,
} = require('../controllers/customerController');

const router = express.Router();

// ── Validation helper ─────────────────────────────────────────────────────────
const handleValidation = (req, res, next) => {
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

// All customer routes require authentication
router.use(authenticate);

/**
 * GET /api/customers
 * Manager/owner management view (list + search + tier filter)
 */
router.get(
    '/',
    authorize('owner', 'manager'),
    getCustomers
);

/**
 * GET /api/customers/search?phone=
 * Point-of-sale lookup. Available to attendants/supervisors too, since
 * this is what a sale screen calls before linking a customer to a sale.
 * NOTE: must be registered before /:id so "search" isn't captured as
 * an :id param.
 */
router.get(
    '/search',
    authorize('owner', 'manager', 'supervisor', 'attendant'),
    [query('phone').notEmpty().withMessage('Phone number is required')],
    handleValidation,
    searchCustomerByPhone
);

/**
 * POST /api/customers
 * Register a new loyalty customer. Available to attendants too — a
 * customer may be registered on the spot at point-of-sale so their
 * current purchase can start earning points immediately.
 */
router.post(
    '/',
    authorize('owner', 'manager', 'supervisor', 'attendant'),
    [
        body('name').notEmpty().withMessage('Name is required'),
        body('phone').notEmpty().withMessage('Phone is required'),
        body('email').optional({ checkFalsy: true }).isEmail().withMessage('Invalid email')
    ],
    handleValidation,
    createCustomer
);

/**
 * GET /api/customers/:id
 */
router.get(
    '/:id',
    authorize('owner', 'manager'),
    [param('id').isInt({ min: 1 }).withMessage('Invalid customer ID')],
    handleValidation,
    getCustomerById
);

/**
 * GET /api/customers/:id/transactions
 * Merged purchase + redemption history for this customer.
 */
router.get(
    '/:id/transactions',
    authorize('owner', 'manager'),
    [param('id').isInt({ min: 1 }).withMessage('Invalid customer ID')],
    handleValidation,
    getCustomerTransactions
);

/**
 * PUT /api/customers/:id
 * Update customer details (not points/tier — use dedicated endpoints)
 */
router.put(
    '/:id',
    authorize('owner', 'manager'),
    [
        param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
        body('name').optional().notEmpty().withMessage('Name cannot be empty'),
        body('phone').optional().notEmpty().withMessage('Phone cannot be empty'),
        body('email').optional({ checkFalsy: true }).isEmail().withMessage('Invalid email')
    ],
    handleValidation,
    updateCustomer
);

/**
 * PUT /api/customers/:id/points
 * Manual points adjustment (promotional bonus / correction).
 */
router.put(
    '/:id/points',
    authorize('owner', 'manager'),
    [
        param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
        body('points').isInt().withMessage('Points must be an integer')
    ],
    handleValidation,
    adjustCustomerPoints
);

/**
 * POST /api/customers/:id/redeem
 * Redeem points (decrements balance, writes a ledger row).
 */
router.post(
    '/:id/redeem',
    authorize('owner', 'manager'),
    [
        param('id').isInt({ min: 1 }).withMessage('Invalid customer ID'),
        body('points').isInt({ min: 1 }).withMessage('Points must be a positive integer')
    ],
    handleValidation,
    redeemCustomerPoints
);

module.exports = router;