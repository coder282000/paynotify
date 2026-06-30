// src/controllers/authController.js
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const { verifyPassword } = require('../utils/password');

/**
 * POST /api/auth/login
 * Authenticate user with username and password
 * Returns JWT token if successful
 */
const login = async (req, res) => {
    const { username, password } = req.body;

    try {
        // 1. Find user by username
        const result = await pool.query(
            `SELECT id, username, password_hash, full_name, role, is_active 
             FROM users 
             WHERE username = $1`,
            [username]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid username or password.'
            });
        }

        const user = result.rows[0];

        // 2. Check if user is active
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Account is disabled. Contact administrator.'
            });
        }

        // 3. Verify password
        const isPasswordValid = await verifyPassword(password, user.password_hash);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid username or password.'
            });
        }

        // 4. Update last_login timestamp
        await pool.query(
            'UPDATE users SET last_login = NOW() WHERE id = $1',
            [user.id]
        );

        // 5. Generate JWT token (24 hour expiry)
        const token = jwt.sign(
            {
                userId: user.id,
                username: user.username,
                role: user.role
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // 6. Log successful login
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details) 
             VALUES ($1, 'LOGIN_SUCCESS', $2)`,
            [user.id, `User ${username} logged in successfully`]
        );

        // 7. Return success response
        res.json({
            success: true,
            message: 'Login successful',
            data: {
                token,
                user: {
                    id: user.id,
                    username: user.username,
                    fullName: user.full_name,
                    role: user.role
                }
            }
        });

    } catch (err) {
        console.error('Login error:', err);
        
        // Log failed login attempt
        await pool.query(
            `INSERT INTO audit_logs (event_type, details) 
             VALUES ('LOGIN_FAILED', $1)`,
            [`Failed login attempt for username: ${username}`]
        );

        res.status(500).json({
            success: false,
            message: 'Login failed. Please try again.'
        });
    }
};

/**
 * GET /api/auth/me
 * Get current authenticated user info
 * Requires: Bearer token in Authorization header
 */
const getMe = async (req, res) => {
    try {
        const userId = req.user.userId; // From JWT middleware

        const result = await pool.query(
            `SELECT id, username, full_name, email, phone, role, is_active, created_at, last_login
             FROM users 
             WHERE id = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found.'
            });
        }

        const user = result.rows[0];

        res.json({
            success: true,
            data: {
                id: user.id,
                username: user.username,
                fullName: user.full_name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                isActive: user.is_active,
                createdAt: user.created_at,
                lastLogin: user.last_login
            }
        });

    } catch (err) {
        console.error('GetMe error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch user info.'
        });
    }
};

/**
 * POST /api/auth/logout
 * Logout current user (invalidates token on frontend)
 * Note: JWT tokens are stateless, so logout is mainly for frontend cleanup
 */
const logout = async (req, res) => {
    try {
        const userId = req.user.userId;

        // Log logout event for audit
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details) 
             VALUES ($1, 'LOGOUT', 'User logged out')`,
            [userId]
        );

        res.json({
            success: true,
            message: 'Logout successful'
        });

    } catch (err) {
        console.error('Logout error:', err);
        res.status(500).json({
            success: false,
            message: 'Logout failed.'
        });
    }
};

module.exports = { login, getMe, logout };