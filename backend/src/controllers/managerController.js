// src/controllers/managerController.js
const pool = require('../config/database');

/**
 * GET /api/manager/dashboard
 * Matches ManagerService.getManagerDashboard() expected response
 */
const getManagerDashboard = async (req, res) => {
    try {
        const userId = req.user.userId;

        // ── 1. Get Manager's Station ──────────────────────────
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

        // ── 2. Today's Sales ──────────────────────────────────
        const todayResult = await pool.query(
            `SELECT 
                COALESCE(SUM(amount), 0) as total_sales,
                COUNT(*) as transaction_count
             FROM transactions
             WHERE station_id = $1 
               AND DATE(created_at) = CURRENT_DATE 
               AND status = 'completed'`,
            [stationId]
        );

        const today = todayResult.rows[0];

        // ── 3. Yesterday's Sales (for change calculation) ────
        const yesterdayResult = await pool.query(
            `SELECT COALESCE(SUM(amount), 0) as total_sales
             FROM transactions
             WHERE station_id = $1 
               AND DATE(created_at) = CURRENT_DATE - INTERVAL '1 day'
               AND status = 'completed'`,
            [stationId]
        );

        const yesterday = yesterdayResult.rows[0];

        // ── 4. Active Pumps ──────────────────────────────────
        const pumpResult = await pool.query(
            `SELECT 
                COUNT(*) as total_pumps,
                SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_pumps
             FROM pumps
             WHERE station_id = $1 AND is_active = true`,
            [stationId]
        );

        const pumps = pumpResult.rows[0];

        // ── 5. Active Attendants ──────────────────────────────
        const attendantResult = await pool.query(
            `SELECT 
                COUNT(*) as total_attendants,
                SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_attendants
             FROM employees
             WHERE station_id = $1 AND employee_role = 'attendant'`,
            [stationId]
        );

        const attendants = attendantResult.rows[0];

        // ── Calculate Changes ──────────────────────────────────
        const todaySales = parseFloat(today.total_sales || 0);
        const yesterdaySales = parseFloat(yesterday.total_sales || 0);
        const salesChange = yesterdaySales > 0 
            ? ((todaySales - yesterdaySales) / yesterdaySales) * 100 
            : 0;

        const todayTransactions = parseInt(today.transaction_count || 0);
        const yesterdayTxResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM transactions
             WHERE station_id = $1 
               AND DATE(created_at) = CURRENT_DATE - INTERVAL '1 day'
               AND status = 'completed'`,
            [stationId]
        );
        const yesterdayTx = parseInt(yesterdayTxResult.rows[0].count || 0);
        const transactionChange = yesterdayTx > 0 
            ? ((todayTransactions - yesterdayTx) / yesterdayTx) * 100 
            : 0;

        res.json({
            success: true,
            data: {
                today_sales: todaySales,
                sales_change: Math.round(salesChange * 100) / 100,
                transaction_count: todayTransactions,
                transaction_change: Math.round(transactionChange * 100) / 100,
                active_pumps: parseInt(pumps.active_pumps || 0),
                total_pumps: parseInt(pumps.total_pumps || 0),
                active_attendants: parseInt(attendants.active_attendants || 0),
                total_attendants: parseInt(attendants.total_attendants || 0)
            }
        });

    } catch (err) {
        console.error('getManagerDashboard error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load dashboard data'
        });
    }
};

/**
 * GET /api/manager/alerts
 * Matches ManagerService.getAlerts() expected response
 */
const getAlerts = async (req, res) => {
    try {
        const userId = req.user.userId;

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

        const alerts = [];

        // ── 1. Low Fuel Alerts ──────────────────────────────
        const fuelResult = await pool.query(
            `SELECT 
                pump_number,
                ROUND((current_fuel_level / NULLIF(tank_capacity, 0)) * 100, 1) as percentage
             FROM pumps
             WHERE station_id = $1 
               AND is_active = true
               AND (current_fuel_level / NULLIF(tank_capacity, 0)) * 100 < 20`,
            [stationId]
        );

        fuelResult.rows.forEach(p => {
            alerts.push(
                `${p.pump_number} fuel level low (${p.percentage}%)`
            );
        });

        // ── 2. Pending Shift Reports ──────────────────────
        const shiftResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM shift_reports
             WHERE station_id = $1 AND status = 'pending'`,
            [stationId]
        );

        const pendingShifts = parseInt(shiftResult.rows[0].count || 0);
        if (pendingShifts > 0) {
            alerts.push(`${pendingShifts} shift report(s) pending approval`);
        }

        // ── 3. Pending Employee Approvals ──────────────────
        const empResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM employee_invitations
             WHERE station_id = $1 AND status = 'pending'`,
            [stationId]
        );

        const pendingEmployees = parseInt(empResult.rows[0].count || 0);
        if (pendingEmployees > 0) {
            alerts.push(`${pendingEmployees} employee(s) pending approval`);
        }

        res.json({
            success: true,
            data: {
                alerts: alerts,
                pending_reports: pendingShifts
            }
        });

    } catch (err) {
        console.error('getAlerts error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load alerts'
        });
    }
};

/**
 * GET /api/manager/analytics/sales
 * Matches ManagerService.getSalesAnalytics() expected response
 */
const getSalesAnalytics = async (req, res) => {
    try {
        const userId = req.user.userId;

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

        // ── Get last 7 days sales ──────────────────────────
        const result = await pool.query(
            `SELECT 
                DATE(created_at) as date,
                COALESCE(SUM(amount), 0) as sales
             FROM transactions
             WHERE station_id = $1 
               AND created_at >= NOW() - INTERVAL '7 days'
               AND status = 'completed'
             GROUP BY DATE(created_at)
             ORDER BY date ASC`,
            [stationId]
        );

        // ── Build array of 7 days ──────────────────────────
        const dailySales = [];
        const today = new Date();
        
        for (let i = 6; i >= 0; i--) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);
            const dateStr = date.toISOString().split('T')[0];
            
            const found = result.rows.find(row => 
                row.date.toISOString().split('T')[0] === dateStr
            );
            
            dailySales.push(found ? parseFloat(found.sales) : 0);
        }

        res.json({
            success: true,
            data: {
                daily_sales: dailySales
            }
        });

    } catch (err) {
        console.error('getSalesAnalytics error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load sales analytics'
        });
    }
};

/**
 * GET /api/manager/quick-stats
 * Returns quick stats for dashboard cards
 */
const getQuickStats = async (req, res) => {
    try {
        const userId = req.user.userId;

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

        // ── Active Attendants ──────────────────────────────
        const attendantResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM employees
             WHERE station_id = $1 
               AND employee_role = 'attendant' 
               AND status = 'active'`,
            [stationId]
        );

        // ── Pending Reports ────────────────────────────────
        const pendingResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM shift_reports
             WHERE station_id = $1 AND status = 'pending'`,
            [stationId]
        );

        // ── Low Fuel Pumps ──────────────────────────────────
        const fuelResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM pumps
             WHERE station_id = $1 
               AND is_active = true
               AND (current_fuel_level / NULLIF(tank_capacity, 0)) * 100 < 20`,
            [stationId]
        );

        // ── Today's Sales ──────────────────────────────────
        const salesResult = await pool.query(
            `SELECT COALESCE(SUM(amount), 0) as total
             FROM transactions
             WHERE station_id = $1 
               AND DATE(created_at) = CURRENT_DATE 
               AND status = 'completed'`,
            [stationId]
        );

        res.json({
            success: true,
            data: {
                activeAttendants: parseInt(attendantResult.rows[0].count || 0),
                pendingReports: parseInt(pendingResult.rows[0].count || 0),
                lowFuelPumps: parseInt(fuelResult.rows[0].count || 0),
                totalSales: parseFloat(salesResult.rows[0].total || 0)
            }
        });

    } catch (err) {
        console.error('getQuickStats error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load quick stats'
        });
    }
};

module.exports = {
    getManagerDashboard,
    getAlerts,
    getSalesAnalytics,
    getQuickStats
};