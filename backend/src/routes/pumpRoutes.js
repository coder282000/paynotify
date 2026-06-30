// src/routes/pumpRoutes.js
const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const {
    getAllPumps,
    getPumpById,
    updatePumpStatus,
    updateFuelPrice,
    createPump
} = require('../controllers/pumpController');

const router = express.Router();

// All pump routes require authentication
router.use(authenticate);

// GET /api/pumps - all roles can view pumps
router.get('/', getAllPumps);

// GET /api/pumps/:id
router.get('/:id', getPumpById);

// POST /api/pumps - owner only
router.post('/', authorize('owner'), createPump);

// PUT /api/pumps/:id/status - manager and supervisor only
router.put('/:id/status', authorize('manager', 'supervisor'), updatePumpStatus);

// PUT /api/pumps/:id/price - manager only
router.put('/:id/price', authorize('manager'), updateFuelPrice);

module.exports = router;