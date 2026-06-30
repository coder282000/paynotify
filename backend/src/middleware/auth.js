// src/middleware/auth.js
const jwt = require('jsonwebtoken');

/**
 * Verifies the JWT token in the Authorization header.
 * Attaches decoded user info to req.user on success.
 */
const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            message: 'No token provided. Please login first.'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        // JWT_SECRET is validated at startup in server.js — safe to use directly here
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded; // { userId, username, role, iat, exp }
        next();
    } catch (err) {
        const message = err.name === 'TokenExpiredError'
            ? 'Session expired. Please login again.'
            : 'Invalid token. Please login again.';

        return res.status(401).json({ success: false, message });
    }
};

/**
 * Role-based access control middleware factory.
 * Usage: authorize('manager') or authorize('manager', 'supervisor')
 */
const authorize = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, message: 'Not authenticated.' });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Required role: ${allowedRoles.join(' or ')}.`
            });
        }

        next();
    };
};

module.exports = { authenticate, authorize };
