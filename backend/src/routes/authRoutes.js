// src/routes/authRoutes.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { login, getMe, logout } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// ── Validation rules ──────────────────────────────────────────────────────────
const loginValidation = [
    body('username')
        .trim()
        .notEmpty().withMessage('Username is required.')
        .isLength({ max: 50 }).withMessage('Username too long.'),

    body('password')
        .notEmpty().withMessage('Password is required.')
        .isLength({ min: 3, max: 100 }).withMessage('Password must be 3–100 characters.'),
];

// ── Validation error handler ──────────────────────────────────────────────────
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

// ── Routes ────────────────────────────────────────────────────────────────────
// POST /api/auth/login
router.post('/login', loginValidation, handleValidation, login);

// GET /api/auth/me  (requires token)
router.get('/me', authenticate, getMe);

// POST /api/auth/logout  (requires token)
router.post('/logout', authenticate, logout);

module.exports = router;
