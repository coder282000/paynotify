// src/controllers/employeeController.js
const pool = require('../config/database');
const { hashPassword } = require('../utils/password');
const crypto = require('crypto');
const { sendInvitationEmailWithRetry, sendApprovalEmail } = require('../utils/email');

/**
 * Generate a secure invitation token
 */
const generateInviteToken = () => {
    return crypto.randomBytes(32).toString('hex');
};

// ──────────────────────────────────────────────────────────────────────────────
// VALIDATE INVITE
// ──────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/public/invite/:token
 * Validate invitation token (Public endpoint)
 */
const validateInvite = async (req, res) => {
    const { token } = req.params;

    try {
        const result = await pool.query(
            `SELECT 
                ei.id as invitation_id,
                ei.email, 
                ei.full_name, 
                ei.role, 
                ei.station_id, 
                ei.phone, 
                ei.employee_role, 
                ei.assigned_pump_id, 
                ei.status, 
                ei.expires_at,
                s.id as station_id,
                s.station_name
             FROM employee_invitations ei
             LEFT JOIN stations s ON ei.station_id = s.id
             WHERE ei.token = $1`,
            [token]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invalid or expired invitation link.'
            });
        }

        const invite = result.rows[0];

        if (new Date(invite.expires_at) < new Date()) {
            await pool.query(
                'UPDATE employee_invitations SET status = $1 WHERE id = $2',
                ['expired', invite.invitation_id]
            );
            return res.status(410).json({
                success: false,
                message: 'This invitation has expired. Please request a new one.'
            });
        }

        if (invite.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: `This invitation has already been ${invite.status}.`
            });
        }

        res.json({
            success: true,
            data: {
                email: invite.email,
                fullName: invite.full_name,
                role: invite.role,
                stationName: invite.station_name,
                stationId: invite.station_id,
                phone: invite.phone,
                employeeRole: invite.employee_role,
                assignedPumpId: invite.assigned_pump_id,
                expiresAt: invite.expires_at
            }
        });

    } catch (err) {
        console.error('❌ Validate invite error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to validate invitation.'
        });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// REGISTER EMPLOYEE
// ──────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/public/register
 * Complete registration using invitation token (Public endpoint)
 */
const registerEmployee = async (req, res) => {
    const { token, username, password, confirm_password } = req.body;

    try {
        if (!token || !username || !password || !confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: token, username, password, confirm_password'
            });
        }

        if (password !== confirm_password) {
            return res.status(400).json({
                success: false,
                message: 'Passwords do not match'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters'
            });
        }

        if (username.length < 3) {
            return res.status(400).json({
                success: false,
                message: 'Username must be at least 3 characters'
            });
        }

        const inviteResult = await pool.query(
            `SELECT id, email, full_name, role, station_id, phone, 
                    employee_role, assigned_pump_id, status, expires_at
             FROM employee_invitations 
             WHERE token = $1`,
            [token]
        );

        if (inviteResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invalid invitation link.'
            });
        }

        const invite = inviteResult.rows[0];

        if (new Date(invite.expires_at) < new Date()) {
            await pool.query(
                'UPDATE employee_invitations SET status = $1 WHERE id = $2',
                ['expired', invite.id]
            );
            return res.status(410).json({
                success: false,
                message: 'This invitation has expired. Please request a new one.'
            });
        }

        if (invite.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: 'This invitation has already been used or is no longer valid.'
            });
        }

        const existingUser = await pool.query(
            'SELECT id FROM users WHERE username = $1',
            [username.trim().toLowerCase()]
        );

        if (existingUser.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Username already exists. Please choose a different username.'
            });
        }

        const existingEmail = await pool.query(
            'SELECT id FROM users WHERE email = $1',
            [invite.email]
        );

        if (existingEmail.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'This email is already registered. Please login.'
            });
        }

        await pool.query('BEGIN');

        const hashedPassword = await hashPassword(password);

        const userResult = await pool.query(
            `INSERT INTO users (
                username, password_hash, full_name, email, phone, role, is_active
            ) VALUES ($1, $2, $3, $4, $5, $6, false)
            RETURNING id, username, full_name, email, phone, role, is_active, created_at`,
            [
                username.trim().toLowerCase(),
                hashedPassword,
                invite.full_name,
                invite.email,
                invite.phone || null,
                invite.role
            ]
        );

        const newUser = userResult.rows[0];

        const employeeResult = await pool.query(
            `INSERT INTO employees (
                user_id, employee_role, status, join_date, assigned_pump_id, station_id
            ) VALUES ($1, $2, 'pending', CURRENT_DATE, $3, $4)
            RETURNING id, employee_role, status, join_date, assigned_pump_id`,
            [
                newUser.id,
                invite.employee_role || invite.role,
                invite.assigned_pump_id || null,
                invite.station_id
            ]
        );

        await pool.query(
            'UPDATE employee_invitations SET status = $1, used_at = NOW() WHERE id = $2',
            ['used', invite.id]
        );

        await pool.query('COMMIT');

        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details)
             VALUES ($1, 'EMPLOYEE_REGISTERED', $2)`,
            [newUser.id, `Employee registered via invitation: ${username}`]
        );

        res.status(201).json({
            success: true,
            message: 'Registration successful! Your account is pending approval.',
            data: {
                user: {
                    id: newUser.id,
                    username: newUser.username,
                    fullName: newUser.full_name,
                    email: newUser.email,
                    role: newUser.role,
                    isActive: newUser.is_active,
                    createdAt: newUser.created_at
                },
                employee: {
                    id: employeeResult.rows[0].id,
                    employeeRole: employeeResult.rows[0].employee_role,
                    status: employeeResult.rows[0].status,
                    joinDate: employeeResult.rows[0].join_date
                }
            }
        });

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Register employee error:', err);
        res.status(500).json({
            success: false,
            message: 'Registration failed. Please try again.'
        });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET EMPLOYEES
// ──────────────────────────────────────────────────────────────────────────────

const getEmployees = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { role, status, station_id, search } = req.query;

        let query = `
            SELECT 
                u.id, u.username, u.full_name, u.email, u.phone, u.role,
                u.is_active as user_active, u.created_at as user_created_at, u.last_login,
                e.id as employee_id, e.employee_role, e.status as employee_status,
                e.join_date, e.assigned_pump_id, e.notes as employee_notes,
                e.created_at as employee_created_at,
                p.pump_number as assigned_pump_number,
                s.id as station_id, s.station_name, s.station_code
            FROM users u
            LEFT JOIN employees e ON u.id = e.user_id
            LEFT JOIN pumps p ON e.assigned_pump_id = p.id
            LEFT JOIN stations s ON e.station_id = s.id
            WHERE u.role IN ('manager', 'supervisor', 'attendant')
        `;

        const params = [];
        let paramCount = 1;

        // Role-based filtering
        if (userRole === 'owner') {
            query += ` AND (
                s.id IN (SELECT id FROM stations WHERE owner_id = $${paramCount})
                OR s.id IS NULL
            )`;
            params.push(userId);
            paramCount++;
        } else if (userRole === 'manager') {
            query += ` AND (
                s.id IN (SELECT id FROM stations WHERE manager_id = $${paramCount})
                OR s.id IS NULL
            )`;
            params.push(userId);
            paramCount++;
        }

        if (role) {
            const validRoles = ['attendant', 'supervisor', 'manager'];
            if (!validRoles.includes(role)) {
                return res.status(400).json({ 
                    success: false, 
                    message: `Invalid role. Must be one of: ${validRoles.join(', ')}` 
                });
            }
            query += ` AND u.role = $${paramCount}`;
            params.push(role);
            paramCount++;
        }

        if (status) {
            const validStatuses = ['active', 'inactive', 'pending', 'suspended'];
            if (!validStatuses.includes(status)) {
                return res.status(400).json({ 
                    success: false, 
                    message: `Invalid status. Must be one of: ${validStatuses.join(', ')}` 
                });
            }
            query += ` AND e.status = $${paramCount}`;
            params.push(status);
            paramCount++;
        }

        if (station_id && userRole === 'owner') {
            query += ` AND s.id = $${paramCount}`;
            params.push(station_id);
            paramCount++;
        }

        if (search) {
            query += ` AND (u.full_name ILIKE $${paramCount} OR u.username ILIKE $${paramCount})`;
            params.push(`%${search}%`);
            paramCount++;
        }

        query += ` ORDER BY u.full_name ASC`;

        const result = await pool.query(query, params);

        const employees = result.rows.map(row => ({
            id: row.id,
            username: row.username,
            fullName: row.full_name,
            email: row.email,
            phone: row.phone,
            role: row.role,
            isActive: row.user_active,
            createdAt: row.user_created_at,
            lastLogin: row.last_login,
            employeeProfile: row.employee_id ? {
                id: row.employee_id,
                employeeRole: row.employee_role,
                status: row.employee_status || 'active',
                joinDate: row.join_date,
                notes: row.employee_notes,
                createdAt: row.employee_created_at,
            } : null,
            assignedPump: row.assigned_pump_id ? {
                id: row.assigned_pump_id,
                number: row.assigned_pump_number
            } : null,
            station: row.station_id ? {
                id: row.station_id,
                name: row.station_name,
                code: row.station_code
            } : null
        }));

        res.json({ success: true, data: employees, count: employees.length });

    } catch (err) {
        console.error('Get employees error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve employees' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET EMPLOYEE BY ID
// ──────────────────────────────────────────────────────────────────────────────

const getEmployeeById = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid employee ID' });
        }

        const query = `
            SELECT 
                u.id, u.username, u.full_name, u.email, u.phone, u.role,
                u.is_active as user_active, u.created_at as user_created_at, u.last_login,
                e.id as employee_id, e.employee_role, e.status as employee_status,
                e.join_date, e.assigned_pump_id, e.notes as employee_notes,
                e.created_at as employee_created_at,
                p.pump_number as assigned_pump_number,
                s.id as station_id, s.station_name, s.station_code
            FROM users u
            LEFT JOIN employees e ON u.id = e.user_id
            LEFT JOIN pumps p ON e.assigned_pump_id = p.id
            LEFT JOIN stations s ON e.station_id = s.id
            WHERE u.id = $1 AND u.role IN ('manager', 'supervisor', 'attendant')
        `;

        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Employee not found' });
        }

        const row = result.rows[0];

        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE manager_id = $1 AND id = $2',
                [userId, row.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You do not manage this employee\'s station.' 
                });
            }
        } else if (userRole === 'owner') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE owner_id = $1 AND id = $2',
                [userId, row.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You do not own this employee\'s station.' 
                });
            }
        }

        const employee = {
            id: row.id,
            username: row.username,
            fullName: row.full_name,
            email: row.email,
            phone: row.phone,
            role: row.role,
            isActive: row.user_active,
            createdAt: row.user_created_at,
            lastLogin: row.last_login,
            employeeProfile: row.employee_id ? {
                id: row.employee_id,
                employeeRole: row.employee_role,
                status: row.employee_status || 'active',
                joinDate: row.join_date,
                notes: row.employee_notes,
                createdAt: row.employee_created_at,
            } : null,
            assignedPump: row.assigned_pump_id ? {
                id: row.assigned_pump_id,
                number: row.assigned_pump_number
            } : null,
            station: row.station_id ? {
                id: row.station_id,
                name: row.station_name,
                code: row.station_code
            } : null
        };

        res.json({ success: true, data: employee });

    } catch (err) {
        console.error('Get employee by ID error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve employee' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// CREATE EMPLOYEE (Direct add)
// ──────────────────────────────────────────────────────────────────────────────

const createEmployee = async (req, res) => {
    const { username, password, full_name, email, phone, role, station_id, assigned_pump_id } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (!username || !password || !full_name || !role) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required fields: username, password, full_name, role' 
            });
        }

        const validRoles = ['attendant', 'supervisor', 'manager'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ 
                success: false, 
                message: `Invalid role. Must be one of: ${validRoles.join(', ')}` 
            });
        }

        if (userRole === 'manager' && role === 'manager') {
            return res.status(403).json({ 
                success: false, 
                message: 'Access denied. Managers cannot create other managers.' 
            });
        }

        const existing = await pool.query(
            'SELECT id FROM users WHERE username = $1', 
            [username.trim().toLowerCase()]
        );
        if (existing.rows.length > 0) {
            return res.status(409).json({ success: false, message: 'Username already exists' });
        }

        let stationId = station_id;

        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE manager_id = $1', 
                [userId]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You are not assigned to any station.' 
                });
            }
            stationId = stationCheck.rows[0].id;
        } else if (userRole === 'owner') {
            if (!station_id) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Station ID is required for owners to create employees' 
                });
            }
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2', 
                [station_id, userId]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You do not own this station.' 
                });
            }
        }

        const hashedPassword = await hashPassword(password);

        await pool.query('BEGIN');

        const userResult = await pool.query(
            `INSERT INTO users (username, password_hash, full_name, email, phone, role, is_active)
             VALUES ($1, $2, $3, $4, $5, $6, true)
             RETURNING id, username, full_name, email, phone, role, is_active, created_at`,
            [username.trim().toLowerCase(), hashedPassword, full_name, email || null, phone || null, role]
        );

        const newUser = userResult.rows[0];

        await pool.query(
            `INSERT INTO employees (user_id, employee_role, status, join_date, assigned_pump_id, station_id)
             VALUES ($1, $2, 'active', CURRENT_DATE, $3, $4)`,
            [newUser.id, role, assigned_pump_id || null, stationId]
        );

        await pool.query('COMMIT');

        res.status(201).json({ 
            success: true, 
            message: 'Employee created successfully', 
            data: newUser 
        });

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Create employee error:', err);
        res.status(500).json({ success: false, message: 'Failed to create employee' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// UPDATE EMPLOYEE
// ──────────────────────────────────────────────────────────────────────────────

const updateEmployee = async (req, res) => {
    const { id } = req.params;
    const { full_name, email, phone, role, status, assigned_pump_id, is_active } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid employee ID' });
        }

        const employeeCheck = await pool.query(
            `SELECT u.id, u.role, u.is_active, e.id as employee_id, e.station_id
             FROM users u
             LEFT JOIN employees e ON u.id = e.user_id
             WHERE u.id = $1 AND u.role IN ('manager', 'supervisor', 'attendant')`,
            [id]
        );

        if (employeeCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Employee not found' });
        }

        const employee = employeeCheck.rows[0];

        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE manager_id = $1 AND id = $2', 
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You can only update employees at your station.' 
                });
            }
            if (role && role === 'manager') {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. Managers cannot change role to manager.' 
                });
            }
        } else if (userRole === 'owner') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE owner_id = $1 AND id = $2', 
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You can only update employees at your stations.' 
                });
            }
        }

        await pool.query('BEGIN');

        const updates = [];
        const values = [];
        let paramCount = 1;

        if (full_name !== undefined) { 
            updates.push(`full_name = $${paramCount}`); 
            values.push(full_name); 
            paramCount++; 
        }
        if (email !== undefined) { 
            updates.push(`email = $${paramCount}`); 
            values.push(email || null); 
            paramCount++; 
        }
        if (phone !== undefined) { 
            updates.push(`phone = $${paramCount}`); 
            values.push(phone || null); 
            paramCount++; 
        }
        if (role !== undefined) {
            const validRoles = ['attendant', 'supervisor', 'manager'];
            if (!validRoles.includes(role)) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    success: false, 
                    message: `Invalid role. Must be one of: ${validRoles.join(', ')}` 
                });
            }
            updates.push(`role = $${paramCount}`); 
            values.push(role); 
            paramCount++;
        }
        if (is_active !== undefined) { 
            updates.push(`is_active = $${paramCount}`); 
            values.push(is_active); 
            paramCount++; 
        }

        if (updates.length > 0) {
            values.push(id);
            const userQuery = `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${paramCount}`;
            await pool.query(userQuery, values);
        }

        const empUpdates = [];
        const empValues = [];
        let empCount = 1;

        if (status !== undefined) {
            const validStatuses = ['active', 'inactive', 'pending', 'suspended'];
            if (!validStatuses.includes(status)) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    success: false, 
                    message: `Invalid status. Must be one of: ${validStatuses.join(', ')}` 
                });
            }
            empUpdates.push(`status = $${empCount}`); 
            empValues.push(status); 
            empCount++;
        }
        if (assigned_pump_id !== undefined) {
            empUpdates.push(`assigned_pump_id = $${empCount}`); 
            empValues.push(assigned_pump_id || null); 
            empCount++;
        }

        if (empUpdates.length > 0 && employee.employee_id) {
            empValues.push(employee.employee_id);
            const empQuery = `UPDATE employees SET ${empUpdates.join(', ')}, updated_at = NOW() WHERE id = $${empCount}`;
            await pool.query(empQuery, empValues);
        }

        await pool.query('COMMIT');

        res.json({ success: true, message: 'Employee updated successfully' });

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Update employee error:', err);
        res.status(500).json({ success: false, message: 'Failed to update employee' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// DELETE EMPLOYEE (Soft delete)
// ──────────────────────────────────────────────────────────────────────────────

const deleteEmployee = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid employee ID' });
        }

        const employeeCheck = await pool.query(
            `SELECT u.id, u.role, e.id as employee_id, e.station_id
             FROM users u
             LEFT JOIN employees e ON u.id = e.user_id
             WHERE u.id = $1 AND u.role IN ('manager', 'supervisor', 'attendant')`,
            [id]
        );

        if (employeeCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Employee not found' });
        }

        const employee = employeeCheck.rows[0];

        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE manager_id = $1 AND id = $2', 
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ success: false, message: 'Access denied.' });
            }
            if (employee.role === 'manager') {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. Managers cannot deactivate other managers.' 
                });
            }
        } else if (userRole === 'owner') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE owner_id = $1 AND id = $2', 
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ success: false, message: 'Access denied.' });
            }
        }

        await pool.query('BEGIN');
        await pool.query('UPDATE users SET is_active = false, updated_at = NOW() WHERE id = $1', [id]);
        await pool.query('UPDATE employees SET status = $1, updated_at = NOW() WHERE user_id = $2', ['inactive', id]);
        await pool.query('COMMIT');

        res.json({ success: true, message: 'Employee deactivated successfully' });

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Delete employee error:', err);
        res.status(500).json({ success: false, message: 'Failed to deactivate employee' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET EMPLOYEE STATS
// ──────────────────────────────────────────────────────────────────────────────

const getEmployeeStats = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;

        let query = `
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN u.role = 'attendant' THEN 1 END) as attendants,
                COUNT(CASE WHEN u.role = 'supervisor' THEN 1 END) as supervisors,
                COUNT(CASE WHEN u.role = 'manager' THEN 1 END) as managers,
                COUNT(CASE WHEN e.status = 'active' THEN 1 END) as active,
                COUNT(CASE WHEN e.status = 'inactive' THEN 1 END) as inactive,
                COUNT(CASE WHEN e.status = 'pending' THEN 1 END) as pending,
                COUNT(CASE WHEN e.status = 'suspended' THEN 1 END) as suspended
            FROM users u
            LEFT JOIN employees e ON u.id = e.user_id
            WHERE u.role IN ('manager', 'supervisor', 'attendant')
        `;

        const params = [];

        if (userRole === 'manager') {
            query += ` AND EXISTS (SELECT 1 FROM stations s WHERE s.manager_id = $1 AND s.id = e.station_id)`;
            params.push(userId);
        } else if (userRole === 'owner') {
            query += ` AND EXISTS (SELECT 1 FROM stations s WHERE s.owner_id = $1 AND s.id = e.station_id)`;
            params.push(userId);
        }

        const result = await pool.query(query, params);

        res.json({ success: true, data: result.rows[0] });

    } catch (err) {
        console.error('Get employee stats error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve employee statistics' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// INVITE EMPLOYEE
// ──────────────────────────────────────────────────────────────────────────────

const inviteEmployee = async (req, res) => {
    const { email, full_name, role, station_id, phone, employee_role, assigned_pump_id } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (!email || !full_name || !role) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required fields: email, full_name, role' 
            });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ success: false, message: 'Invalid email address' });
        }

        const validRoles = ['attendant', 'supervisor', 'manager'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ 
                success: false, 
                message: `Invalid role. Must be one of: ${validRoles.join(', ')}` 
            });
        }

        if (userRole === 'manager' && role === 'manager') {
            return res.status(403).json({ 
                success: false, 
                message: 'Access denied. Managers cannot invite other managers.' 
            });
        }

        const existing = await pool.query(
            'SELECT id FROM users WHERE email = $1', 
            [email.trim().toLowerCase()]
        );
        if (existing.rows.length > 0) {
            return res.status(409).json({ 
                success: false, 
                message: 'This email is already registered.' 
            });
        }

        const pendingInvite = await pool.query(
            'SELECT id FROM employee_invitations WHERE email = $1 AND status = $2',
            [email.trim().toLowerCase(), 'pending']
        );
        if (pendingInvite.rows.length > 0) {
            return res.status(409).json({ 
                success: false, 
                message: 'An invitation has already been sent to this email.' 
            });
        }

        let stationId = station_id;
        let stationName = '';

        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id, station_name FROM stations WHERE manager_id = $1', 
                [userId]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You are not assigned to any station.' 
                });
            }
            stationId = stationCheck.rows[0].id;
            stationName = stationCheck.rows[0].station_name;

            if (station_id && station_id !== stationId) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Managers can only invite employees to their assigned station.' 
                });
            }

        } else if (userRole === 'owner') {
            if (!station_id) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Station ID is required for owners to invite employees.' 
                });
            }

            const stationCheck = await pool.query(
                'SELECT id, station_name FROM stations WHERE id = $1 AND owner_id = $2', 
                [station_id, userId]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You do not own this station or it does not exist.' 
                });
            }
            stationId = stationCheck.rows[0].id;
            stationName = stationCheck.rows[0].station_name;

        } else {
            return res.status(403).json({ 
                success: false, 
                message: 'Only owners and managers can invite employees.' 
            });
        }

        const inviterResult = await pool.query(
            'SELECT full_name FROM users WHERE id = $1', 
            [userId]
        );
        const invitedBy = inviterResult.rows[0]?.full_name || 'Manager';

        const inviteToken = generateInviteToken();
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 48);

        const inviteResult = await pool.query(
            `INSERT INTO employee_invitations (
                email, full_name, role, station_id, phone, employee_role,
                assigned_pump_id, token, expires_at, invited_by, status
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending')
            RETURNING id, token, email, full_name, role, expires_at`,
            [
                email.trim().toLowerCase(), full_name, role, stationId, phone || null,
                employee_role || role, assigned_pump_id || null, inviteToken, expiresAt, userId
            ]
        );

        const invitation = inviteResult.rows[0];

        // Send email in background (non-blocking)
        setImmediate(async () => {
            const result = await sendInvitationEmailWithRetry(
                email, full_name, role, stationName, invitedBy, inviteToken
            );
            if (result.success) {
                console.log(`✅ Email sent to ${email} on attempt ${result.attempt}`);
            } else {
                console.error(`❌ Email failed for ${email} after ${result.attempt || 3} attempts`);
            }
        });

        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details) 
             VALUES ($1, 'EMPLOYEE_INVITED', $2)`,
            [userId, `Invited ${full_name} (${email}) as ${role} at ${stationName}`]
        );

        res.status(201).json({
            success: true,
            message: `Invitation sent to ${email}`,
            data: {
                id: invitation.id,
                email: invitation.email,
                fullName: invitation.full_name,
                role: invitation.role,
                stationId: stationId,
                stationName: stationName,
                expiresAt: invitation.expires_at,
                emailStatus: 'pending'
            }
        });

    } catch (err) {
        console.error('Invite employee error:', err);
        res.status(500).json({ success: false, message: 'Failed to send invitation' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// RESEND INVITATION
// ──────────────────────────────────────────────────────────────────────────────

const resendInvitation = async (req, res) => {
    const { email, full_name, role } = req.body;
    const userId = req.user.userId;

    try {
        const inviteResult = await pool.query(
            `SELECT id, token, station_id, status, expires_at 
             FROM employee_invitations 
             WHERE email = $1 AND status = $2`,
            [email.trim().toLowerCase(), 'pending']
        );

        if (inviteResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'No pending invitation found for this email.' 
            });
        }

        const invite = inviteResult.rows[0];

        const stationResult = await pool.query(
            'SELECT station_name FROM stations WHERE id = $1', 
            [invite.station_id]
        );
        const stationName = stationResult.rows[0]?.station_name || 'your station';

        const inviterResult = await pool.query(
            'SELECT full_name FROM users WHERE id = $1', 
            [userId]
        );
        const invitedBy = inviterResult.rows[0]?.full_name || 'Manager';

        setImmediate(async () => {
            const result = await sendInvitationEmailWithRetry(
                email, full_name, role, stationName, invitedBy, invite.token
            );
            if (result.success) {
                console.log(`✅ Email resent to ${email} on attempt ${result.attempt}`);
            } else {
                console.error(`❌ Email failed for ${email} after ${result.attempt || 3} attempts`);
            }
        });

        const newExpiry = new Date();
        newExpiry.setHours(newExpiry.getHours() + 48);
        await pool.query(
            'UPDATE employee_invitations SET expires_at = $1, updated_at = NOW() WHERE id = $2', 
            [newExpiry, invite.id]
        );

        res.json({ success: true, message: 'Invitation resent successfully.' });

    } catch (err) {
        console.error('Resend invitation error:', err);
        res.status(500).json({ success: false, message: 'Failed to resend invitation.' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET ALL PENDING (Invitations + Registrations)
// ──────────────────────────────────────────────────────────────────────────────

const getAllPending = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Get both:
        // 1. Pending invitations (no user yet)
        // 2. Pending registrations (user registered, waiting for approval)
        let query = `
            SELECT 
                ei.id as invitation_id,
                ei.email,
                ei.full_name,
                ei.role,
                ei.phone,
                ei.created_at as invited_at,
                ei.expires_at,
                'invitation' as type,
                NULL as username,
                NULL as user_id,
                NULL as employee_id,
                NULL as registration_date,
                s.id as station_id,
                s.station_name
            FROM employee_invitations ei
            LEFT JOIN stations s ON ei.station_id = s.id
            WHERE ei.status = 'pending'
            AND ei.expires_at > NOW()

            UNION ALL

            SELECT 
                NULL as invitation_id,
                u.email,
                u.full_name,
                u.role,
                u.phone,
                u.created_at as invited_at,
                NULL as expires_at,
                'registration' as type,
                u.username,
                u.id as user_id,
                e.id as employee_id,
                u.created_at as registration_date,
                s.id as station_id,
                s.station_name
            FROM users u
            LEFT JOIN employees e ON u.id = e.user_id
            LEFT JOIN stations s ON e.station_id = s.id
            WHERE u.is_active = false
            AND u.role IN ('attendant', 'supervisor', 'manager')
            AND e.status = 'pending'
        `;

        const params = [];
        let paramCount = 1;

        // Role-based filtering
        if (userRole === 'manager') {
            query = `
                SELECT * FROM (${query}) AS all_pending
                WHERE station_id IN (SELECT id FROM stations WHERE manager_id = $1)
            `;
            params.push(userId);
        } else if (userRole === 'owner') {
            query = `
                SELECT * FROM (${query}) AS all_pending
                WHERE station_id IN (SELECT id FROM stations WHERE owner_id = $1)
            `;
            params.push(userId);
        }

        query += ` ORDER BY invited_at DESC`;

        const result = await pool.query(query, params);

        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });

    } catch (err) {
        console.error('❌ Get all pending error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending items'
        });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET PENDING REGISTRATIONS (Legacy - kept for compatibility)
// ──────────────────────────────────────────────────────────────────────────────

const getPendingRegistrations = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;

        let query = `
            SELECT 
                u.id, u.username, u.full_name, u.email, u.phone, u.role,
                u.created_at as registration_date,
                e.id as employee_id, e.employee_role, e.status as employee_status,
                e.join_date, e.assigned_pump_id,
                p.pump_number as assigned_pump_number,
                s.id as station_id, s.station_name, s.station_code
            FROM users u
            LEFT JOIN employees e ON u.id = e.user_id
            LEFT JOIN pumps p ON e.assigned_pump_id = p.id
            LEFT JOIN stations s ON e.station_id = s.id
            WHERE u.is_active = false
            AND u.role IN ('attendant', 'supervisor', 'manager')
            AND e.status = 'pending'
        `;

        const params = [];

        if (userRole === 'manager') {
            query += ` AND EXISTS (SELECT 1 FROM stations s2 WHERE s2.manager_id = $1 AND s2.id = s.id)`;
            params.push(userId);
        } else if (userRole === 'owner') {
            query += ` AND (s.id IS NULL OR EXISTS (SELECT 1 FROM stations s2 WHERE s2.owner_id = $1 AND s2.id = s.id))`;
            params.push(userId);
        }

        query += ` ORDER BY u.created_at DESC`;

        const result = await pool.query(query, params);

        const pendingEmployees = result.rows.map(row => ({
            id: row.id,
            username: row.username,
            fullName: row.full_name,
            email: row.email,
            phone: row.phone,
            role: row.role,
            registrationDate: row.registration_date,
            employeeId: row.employee_id,
            employeeRole: row.employee_role,
            status: row.employee_status,
            assignedPump: row.assigned_pump_id ? { 
                id: row.assigned_pump_id, 
                number: row.assigned_pump_number 
            } : null,
            station: row.station_id ? { 
                id: row.station_id, 
                name: row.station_name, 
                code: row.station_code 
            } : null
        }));

        res.json({ 
            success: true, 
            data: pendingEmployees, 
            count: pendingEmployees.length 
        });

    } catch (err) {
        console.error('Get pending registrations error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to fetch pending registrations' 
        });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// APPROVE EMPLOYEE
// ──────────────────────────────────────────────────────────────────────────────

const approveEmployee = async (req, res) => {
    const { id } = req.params;
    const { approved, notes } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid employee ID' });
        }

        const employeeCheck = await pool.query(
            `SELECT u.id, u.full_name, u.email, u.role, u.username,
                    e.id as employee_id, e.status as employee_status, 
                    e.station_id, s.manager_id, s.owner_id, s.station_name
             FROM users u
             LEFT JOIN employees e ON u.id = e.user_id
             LEFT JOIN stations s ON e.station_id = s.id
             WHERE u.id = $1 AND u.is_active = false AND e.status = 'pending'`,
            [id]
        );

        if (employeeCheck.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Pending employee not found or already processed' 
            });
        }

        const employee = employeeCheck.rows[0];

        // Authorization check
        if (userRole === 'manager') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE manager_id = $1 AND id = $2',
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You can only approve employees at your station.' 
                });
            }
        } else if (userRole === 'owner') {
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE owner_id = $1 AND id = $2',
                [userId, employee.station_id]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({ 
                    success: false, 
                    message: 'Access denied. You can only approve employees at your stations.' 
                });
            }
        }

        await pool.query('BEGIN');

        if (approved === true) {
            // Approve the employee
            await pool.query(
                'UPDATE users SET is_active = true, updated_at = NOW() WHERE id = $1', 
                [id]
            );
            await pool.query(
                'UPDATE employees SET status = $1, updated_at = NOW() WHERE user_id = $2', 
                ['active', id]
            );

            await pool.query(
                `INSERT INTO audit_logs (user_id, event_type, details) 
                 VALUES ($1, 'EMPLOYEE_APPROVED', $2)`,
                [userId, `Approved employee ${employee.full_name} (${employee.email})`]
            );

            await pool.query('COMMIT');

            // Send approval email (non-blocking)
            setImmediate(async () => {
                try {
                    await sendApprovalEmail(
                        employee.email,
                        employee.full_name,
                        employee.username,
                        employee.role,
                        employee.station_name,
                        process.env.FRONTEND_URL || 'http://localhost:3001'
                    );
                    console.log(`✅ Approval email sent to ${employee.email}`);
                } catch (emailError) {
                    console.error(`❌ Failed to send approval email: ${emailError.message}`);
                }
            });

            res.json({ 
                success: true, 
                message: `Employee ${employee.full_name} has been approved successfully.` 
            });

        } else {
            // Reject the employee
            await pool.query('DELETE FROM employees WHERE user_id = $1', [id]);
            await pool.query('DELETE FROM users WHERE id = $1', [id]);

            await pool.query(
                `INSERT INTO audit_logs (user_id, event_type, details) 
                 VALUES ($1, 'EMPLOYEE_REJECTED', $2)`,
                [userId, `Rejected employee ${employee.full_name} (${employee.email}). Reason: ${notes || 'Not specified'}`]
            );

            await pool.query('COMMIT');

            res.json({ 
                success: true, 
                message: `Employee ${employee.full_name} has been rejected.` 
            });
        }

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('❌ Approve employee error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to process approval',
            error: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ──────────────────────────────────────────────────────────────────────────────

module.exports = {
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
    getAllPending,      // ← NEW: Shows invitations + registrations
    approveEmployee
};