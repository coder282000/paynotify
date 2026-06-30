// src/routes/publicRoutes.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { validateInvite, registerEmployee } = require('../controllers/employeeController');

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

// ── Public routes ─────────────────────────────────────────────────────────────

/**
 * GET /api/public/invite/:token
 * Validate invitation token
 */
router.get('/invite/:token', validateInvite);

/**
 * POST /api/public/register
 * Complete registration using invitation token
 */
router.post(
    '/register',
    [
        body('token').notEmpty().withMessage('Invitation token is required'),
        body('username')
            .trim()
            .notEmpty().withMessage('Username is required')
            .isLength({ min: 3, max: 50 }).withMessage('Username must be 3-50 characters')
            .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username can only contain letters, numbers, and underscores'),
        body('password')
            .notEmpty().withMessage('Password is required')
            .isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
        body('confirm_password')
            .notEmpty().withMessage('Confirm password is required'),
    ],
    handleValidation,
    registerEmployee
);

module.exports = router;