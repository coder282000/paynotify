// src/routes/transactionRoutes.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');
const {
    recordCashSale,
    recordCardSale,
    initiateMpesa,
    getTransactions,
    getTransactionSummary
} = require('../controllers/transactionController');

const router = express.Router();
router.use(authenticate);

// ── Validation helper ─────────────────────────────────────────────────────────
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

// ── Shared sale validation ────────────────────────────────────────────────────
const saleValidation = [
    body('pump_id').isInt({ min: 1 }).withMessage('pump_id must be a valid integer.'),
    body('amount').isFloat({ min: 1 }).withMessage('amount must be greater than 0.'),
    body('customer_name').optional().trim().isLength({ max: 100 }),
    body('liters_dispensed').optional().isFloat({ min: 0 }),
    body('note').optional().trim().isLength({ max: 500 }),
];

// GET /api/transactions — attendants see own, managers/supervisors see all
router.get('/', getTransactions);

// GET /api/transactions/summary
router.get('/summary', authorize('manager', 'supervisor'), getTransactionSummary);

// POST /api/transactions/cash
router.post('/cash', saleValidation, validate, recordCashSale);

// POST /api/transactions/card
router.post('/card', saleValidation, validate, recordCardSale);

// POST /api/transactions/mpesa (placeholder until Phase 6)
router.post('/mpesa', initiateMpesa);

module.exports = router;
