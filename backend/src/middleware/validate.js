// src/middleware/validate.js
const { body, validationResult } = require('express-validator');

// Login validation rules
const validateLogin = [
    body('username')
        .trim()
        .isLength({ min: 2, max: 50 })
        .withMessage('Username must be between 2 and 50 characters')
        .escape(),
    body('password')
        .isLength({ min: 3 })
        .withMessage('Password must be at least 3 characters'),
    (req, res, next) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ 
                success: false, 
                errors: errors.array() 
            });
        }
        next();
    }
];

// Transaction validation (for later)
const validateTransaction = [
    body('amount')
        .isFloat({ min: 1 })
        .withMessage('Amount must be greater than 0'),
    body('paymentType')
        .isIn(['mpesa', 'cash', 'card', 'qr'])
        .withMessage('Invalid payment type'),
    (req, res, next) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ 
                success: false, 
                errors: errors.array() 
            });
        }
        next();
    }
];

module.exports = { validateLogin, validateTransaction };