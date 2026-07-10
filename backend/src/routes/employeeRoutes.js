// src/routes/employeeRoutes.js
const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');
const {
    getEmployees,
    getEmployeeById,
    createEmployee,
    updateEmployee,
    deleteEmployee,
    getEmployeeStats,
    inviteEmployee,
    resendInvitation,
    validateInvite,
    registerEmployee,
    getPendingRegistrations,
    getAllPending,      // ✅ ADDED: New function
    approveEmployee
} = require('../controllers/employeeController');

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

// ── Validation rules ─────────────────────────────────────────────────────────

const inviteValidation = [
    body('email')
        .trim()
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Invalid email address'),

    body('full_name')
        .trim()
        .notEmpty().withMessage('Full name is required')
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be 2-100 characters'),

    body('role')
        .notEmpty().withMessage('Role is required')
        .isIn(['attendant', 'supervisor', 'manager']).withMessage('Invalid role'),

    // ✅ FIXED: checkFalsy treats "" (empty string sent by frontend when phone is blank)
    // the same as undefined — so the validator is skipped instead of failing on isMobilePhone('')
    body('phone')
        .optional({ checkFalsy: true })
        .trim()
        .isMobilePhone().withMessage('Invalid phone number'),

    // station_id is mandatory when the inviter is an owner,
    // remains optional for managers (who are typically scoped to one station)
    body('station_id')
        .custom((value, { req }) => {
            if (req.user.role === 'owner' && !value) {
                throw new Error('Station ID is required when inviting as owner');
            }
            if (value !== undefined && value !== null && (!Number.isInteger(Number(value)) || Number(value) < 1)) {
                throw new Error('Station ID must be a valid integer');
            }
            return true;
        }),

    // ✅ FIXED: nullable:true so explicit null (not just undefined) is treated as "not provided"
    body('assigned_pump_id')
        .optional({ nullable: true })
        .isInt({ min: 1 }).withMessage('Pump ID must be a valid integer'),

    // ✅ FIXED: only validated/enforced when role === 'attendant' — ignored entirely for manager/supervisor invites,
    // since employee_role is a sub-classification that only makes sense for attendants
    body('employee_role')
        .custom((value, { req }) => {
            if (req.body.role !== 'attendant') {
                return true;
            }
            if (value !== undefined && value !== null && value !== '' &&
                !['attendant', 'seniorAttendant', 'supervisor'].includes(value)) {
                throw new Error('Invalid employee_role');
            }
            return true;
        }),
];

const resendValidation = [
    body('email')
        .trim()
        .notEmpty().withMessage('Email is required')
        .isEmail().withMessage('Invalid email address'),

    body('full_name')
        .trim()
        .notEmpty().withMessage('Full name is required'),

    body('role')
        .notEmpty().withMessage('Role is required'),
];

// ── Routes ────────────────────────────────────────────────────────────────────

// All employee routes require authentication
router.use(authenticate);

/**
 * GET /api/employees
 * List all employees with optional filters
 */
router.get(
    '/',
    authorize('owner', 'manager'),
    getEmployees
);

/**
 * GET /api/employees/stats
 * Get employee statistics
 */
router.get(
    '/stats',
    authorize('owner', 'manager'),
    getEmployeeStats
);

/**
 * GET /api/employees/pending
 * Get pending employee registrations for approval
 * ⚠️ LEGACY: Only shows users who have registered but not yet approved
 * Use /api/employees/all-pending for full list including invitations
 */
router.get(
    '/pending',
    authorize('owner', 'manager'),
    getPendingRegistrations
);

/**
 * GET /api/employees/all-pending
 * Get ALL pending items: invitations + registrations
 * ✅ Shows invitations immediately when sent
 */
router.get(
    '/all-pending',
    authorize('owner', 'manager'),
    getAllPending
);

/**
 * POST /api/employees/invite
 * Send invitation email to employee
 */
router.post(
    '/invite',
    authorize('owner', 'manager'),
    inviteValidation,
    handleValidation,
    inviteEmployee
);

/**
 * POST /api/employees/resend
 * Resend invitation email
 */
router.post(
    '/resend',
    authorize('owner', 'manager'),
    resendValidation,
    handleValidation,
    resendInvitation
);

/**
 * PUT /api/employees/approve/:id
 * Approve or reject pending employee registration
 */
router.put(
    '/approve/:id',
    authorize('owner', 'manager'),
    approveEmployee
);

/**
 * GET /api/employees/:id
 * Get single employee by ID
 */
router.get(
    '/:id',
    authorize('owner', 'manager'),
    getEmployeeById
);

/**
 * POST /api/employees
 * Create new employee (direct add - no invitation)
 */
router.post(
    '/',
    authorize('owner', 'manager'),
    createEmployee
);

/**
 * PUT /api/employees/:id
 * Update employee details
 */
router.put(
    '/:id',
    authorize('owner', 'manager'),
    updateEmployee
);

/**
 * DELETE /api/employees/:id
 * Deactivate employee (soft delete)
 */
router.delete(
    '/:id',
    authorize('owner', 'manager'),
    deleteEmployee
);

module.exports = router;