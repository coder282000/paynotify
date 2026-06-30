// src/routes/stationRoutes.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');
const {
    getStations,
    getStationById,
    createStation,
    updateStation,
    getStationSummary,
    getStationPerformance
} = require('../controllers/stationController');

const router = express.Router();

// All station routes require authentication
router.use(authenticate);

// ── Validation middleware ─────────────────────────────────────────────────────
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

// ── Validation rules ─────────────────────────────────────────────────────────

const createStationValidation = [
    body('station_name')
        .trim()
        .notEmpty().withMessage('Station name is required')
        .isLength({ min: 3, max: 100 }).withMessage('Station name must be 3-100 characters'),
    
    body('station_code')
        .trim()
        .notEmpty().withMessage('Station code is required')
        .isLength({ min: 2, max: 20 }).withMessage('Station code must be 2-20 characters')
        .matches(/^[A-Z0-9]+$/).withMessage('Station code must be uppercase alphanumeric'),
    
    body('location')
        .trim()
        .notEmpty().withMessage('Location is required')
        .isLength({ min: 5, max: 255 }).withMessage('Location must be 5-255 characters'),
    
    body('city')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('City must be max 50 characters'),
    
    body('county')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('County must be max 50 characters'),
    
    body('phone')
        .optional()
        .trim()
        .isMobilePhone().withMessage('Invalid phone number'),
    
    body('email')
        .optional()
        .trim()
        .isEmail().withMessage('Invalid email address'),
    
    body('manager_id')
        .optional()
        .isInt({ min: 1 }).withMessage('Manager ID must be a valid integer'),
    
    body('paybill_number')
        .optional()
        .trim()
        .isLength({ max: 20 }).withMessage('Paybill number must be max 20 characters'),
    
    body('till_number')
        .optional()
        .trim()
        .isLength({ max: 20 }).withMessage('Till number must be max 20 characters'),
];

const updateStationValidation = [
    body('station_name')
        .optional()
        .trim()
        .isLength({ min: 3, max: 100 }).withMessage('Station name must be 3-100 characters'),
    
    body('location')
        .optional()
        .trim()
        .isLength({ min: 5, max: 255 }).withMessage('Location must be 5-255 characters'),
    
    body('city')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('City must be max 50 characters'),
    
    body('county')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('County must be max 50 characters'),
    
    body('phone')
        .optional()
        .trim()
        .isMobilePhone().withMessage('Invalid phone number'),
    
    body('email')
        .optional()
        .trim()
        .isEmail().withMessage('Invalid email address'),
    
    body('status')
        .optional()
        .isIn(['active', 'maintenance', 'closed', 'suspended'])
        .withMessage('Invalid status'),
    
    body('paybill_number')
        .optional()
        .trim()
        .isLength({ max: 20 }).withMessage('Paybill number must be max 20 characters'),
    
    body('till_number')
        .optional()
        .trim()
        .isLength({ max: 20 }).withMessage('Till number must be max 20 characters'),
];

// ── Routes ────────────────────────────────────────────────────────────────────

/**
 * GET /api/stations
 * List all stations for owner (owner only)
 */
router.get(
    '/',
    authorize('owner', 'manager'),
    getStations
);

/**
 * POST /api/stations
 * Create new station (owner only)
 */
router.post(
    '/',
    authorize('owner'),
    createStationValidation,
    handleValidation,
    createStation
);

/**
 * GET /api/stations/:id
 * Get station details (owner or assigned manager)
 */
router.get(
    '/:id',
    authorize('owner', 'manager'),
    getStationById
);

/**
 * PUT /api/stations/:id
 * Update station (owner or assigned manager)
 */
router.put(
    '/:id',
    authorize('owner', 'manager'),
    updateStationValidation,
    handleValidation,
    updateStation
);

/**
 * GET /api/stations/:id/summary
 * Get station daily/period summary (owner or manager)
 */
router.get(
    '/:id/summary',
    authorize('owner', 'manager'),
    getStationSummary
);

/**
 * GET /api/stations/:id/performance
 * Get station performance metrics (owner or manager)
 */
router.get(
    '/:id/performance',
    authorize('owner', 'manager'),
    getStationPerformance
);

module.exports = router;