// src/controllers/notificationController.js
const pool = require('../config/database');

/**
 * GET /api/manager/notifications
 * Get notifications for manager's station
 */
const getNotifications = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 20 } = req.query;

        const stationResult = await pool.query(
            `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
            [userId]
        );

        if (stationResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No station assigned to this manager'
            });
        }

        const stationId = stationResult.rows[0].id;

        const result = await pool.query(
            `SELECT 
                id,
                title,
                message,
                sent_by,
                target_roles,
                priority,
                created_at,
                is_read_by
             FROM notifications
             WHERE station_id = $1
             ORDER BY created_at DESC
             LIMIT $2`,
            [stationId, parseInt(limit)]
        );

        res.json({
            success: true,
            data: result.rows.map(row => ({
                id: row.id,
                title: row.title,
                message: row.message,
                sentBy: row.sent_by,
                targetRoles: row.target_roles || ['attendant'],
                priority: row.priority || 'normal',
                createdAt: row.created_at,
                isReadBy: row.is_read_by || []
            }))
        });

    } catch (err) {
        console.error('Get notifications error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load notifications'
        });
    }
};

/**
 * POST /api/manager/notifications
 * Send notification to staff
 */
const sendNotification = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { title, message, target_roles, priority } = req.body;

        // ── Validate ────────────────────────────────────────────
        if (!title || !message) {
            return res.status(400).json({
                success: false,
                message: 'Title and message are required'
            });
        }

        const validRoles = ['attendant', 'supervisor', 'manager', 'all'];
        if (target_roles && !target_roles.every(r => validRoles.includes(r))) {
            return res.status(400).json({
                success: false,
                message: `Invalid roles. Must be one of: ${validRoles.join(', ')}`
            });
        }

        const validPriorities = ['low', 'normal', 'high', 'urgent'];
        if (priority && !validPriorities.includes(priority)) {
            return res.status(400).json({
                success: false,
                message: `Invalid priority. Must be one of: ${validPriorities.join(', ')}`
            });
        }

        // ── Get manager's station ──────────────────────────────
        const stationResult = await pool.query(
            `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
            [userId]
        );

        if (stationResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No station assigned to this manager'
            });
        }

        const stationId = stationResult.rows[0].id;

        // ── Create notification ─────────────────────────────────
        const result = await pool.query(
            `INSERT INTO notifications 
             (station_id, title, message, sent_by, target_roles, priority)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING *`,
            [stationId, title, message, userId, 
             target_roles || ['attendant'], 
             priority || 'normal']
        );

        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'NOTIFICATION_SENT', $2, $3)`,
            [userId, `Notification sent: ${title}`, stationId]
        );

        res.status(201).json({
            success: true,
            message: 'Notification sent successfully',
            data: result.rows[0]
        });

    } catch (err) {
        console.error('Send notification error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to send notification'
        });
    }
};

/**
 * PUT /api/manager/notifications/:id/read
 * Mark notification as read
 */
const markNotificationRead = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { id } = req.params;

        const stationResult = await pool.query(
            `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
            [userId]
        );

        if (stationResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No station assigned to this manager'
            });
        }

        const stationId = stationResult.rows[0].id;

        // ── Add user to read list ──────────────────────────────
        const result = await pool.query(
            `UPDATE notifications 
             SET is_read_by = array_append(is_read_by, $1)
             WHERE id = $2 AND station_id = $3
             RETURNING id`,
            [userId, id, stationId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Notification not found'
            });
        }

        res.json({
            success: true,
            message: 'Notification marked as read'
        });

    } catch (err) {
        console.error('Mark notification read error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to mark notification as read'
        });
    }
};

module.exports = {
    getNotifications,
    sendNotification,
    markNotificationRead
};