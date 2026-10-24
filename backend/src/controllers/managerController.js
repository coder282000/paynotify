// src/controllers/managerController.js
const pool = require('../config/database');

/**
 * Helper function to get station IDs based on user role
 */
const getStationIds = async (user) => {
    if (user.role === 'owner') {
        // Owner: get all their stations
        const result = await pool.query(
            `SELECT id FROM stations WHERE owner_id = $1 AND is_active = true`,
            [user.userId]
        );
        return result.rows.map(row => row.id);
    } else {
        // Manager/Supervisor: only their assigned station
        const result = await pool.query(
            `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
            [user.userId]
        );
        return result.rows.length > 0 ? [result.rows[0].id] : [];
    }
};

/**
 * GET /api/manager/dashboard
 * Matches ManagerService.getManagerDashboard() expected response
 */
const getManagerDashboard = async (req, res) => {
    try {
        const user = req.user;
        const { station_id } = req.query; // For owners to filter specific station

        // Get station IDs
        let stationIds = await getStationIds(user);
        
        // If owner and station_id provided, filter to that station
        if (user.role === 'owner' && station_id) {
            // Verify station belongs to owner
            const check = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2',
                [station_id, user.userId]
            );
            if (check.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not own this station'
                });
            }
            stationIds = [station_id];
        }

        if (stationIds.length === 0) {
            return res.json({
                success: true,
                data: {
                    today_sales: 0,
                    sales_change: 0,
                    transaction_count: 0,
                    transaction_change: 0,
                    active_pumps: 0,
                    total_pumps: 0,
                    active_attendants: 0,
                    total_attendants: 0,
                    stations_covered: 0
                }
            });
        }

        // ── 1. Today's Sales ──────────────────────────────────
        const todayResult = await pool.query(
            `SELECT 
                COALESCE(SUM(amount), 0) as total_sales,
                COUNT(*) as transaction_count
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND DATE(created_at) = CURRENT_DATE 
               AND status = 'completed'`,
            [stationIds]
        );

        const today = todayResult.rows[0];

        // ── 2. Yesterday's Sales (for change calculation) ────
        const yesterdayResult = await pool.query(
            `SELECT COALESCE(SUM(amount), 0) as total_sales
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND DATE(created_at) = CURRENT_DATE - INTERVAL '1 day'
               AND status = 'completed'`,
            [stationIds]
        );

        const yesterday = yesterdayResult.rows[0];

        // ── 3. Active Pumps ──────────────────────────────────
        const pumpResult = await pool.query(
            `SELECT 
                COUNT(*) as total_pumps,
                SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_pumps
             FROM pumps
             WHERE station_id = ANY($1::uuid[]) AND is_active = true`,
            [stationIds]
        );

        const pumps = pumpResult.rows[0];

        // ── 4. Active Attendants ──────────────────────────────
        const attendantResult = await pool.query(
            `SELECT 
                COUNT(*) as total_attendants,
                SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_attendants
             FROM employees
             WHERE station_id = ANY($1::uuid[]) AND employee_role = 'attendant'`,
            [stationIds]
        );

        const attendants = attendantResult.rows[0];

        // ── 5. Yesterday's Transactions for change ──────────
        const yesterdayTxResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND DATE(created_at) = CURRENT_DATE - INTERVAL '1 day'
               AND status = 'completed'`,
            [stationIds]
        );
        const yesterdayTx = parseInt(yesterdayTxResult.rows[0].count || 0);

        // ── Calculate Changes ──────────────────────────────────
        const todaySales = parseFloat(today.total_sales || 0);
        const yesterdaySales = parseFloat(yesterday.total_sales || 0);
        const salesChange = yesterdaySales > 0 
            ? ((todaySales - yesterdaySales) / yesterdaySales) * 100 
            : 0;

        const todayTransactions = parseInt(today.transaction_count || 0);
        const transactionChange = yesterdayTx > 0 
            ? ((todayTransactions - yesterdayTx) / yesterdayTx) * 100 
            : 0;

        // ── Get station names (for owners) ──────────────────
        let stationNames = [];
        if (user.role === 'owner' && stationIds.length > 1) {
            const namesResult = await pool.query(
                'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
                [stationIds]
            );
            stationNames = namesResult.rows;
        }

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
                total_attendants: parseInt(attendants.total_attendants || 0),
                stations_covered: stationIds.length,
                stations: stationNames,
                is_owner: user.role === 'owner'
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
        const user = req.user;
        const { station_id } = req.query;

        let stationIds = await getStationIds(user);
        
        if (user.role === 'owner' && station_id) {
            const check = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2',
                [station_id, user.userId]
            );
            if (check.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not own this station'
                });
            }
            stationIds = [station_id];
        }

        if (stationIds.length === 0) {
            return res.json({
                success: true,
                data: {
                    alerts: [],
                    pending_reports: 0,
                    stations_covered: 0
                }
            });
        }

        const alerts = [];

        // ── 1. Low Fuel Alerts ──────────────────────────────
        const fuelResult = await pool.query(
            `SELECT 
                pump_number,
                ROUND((current_fuel_level / NULLIF(tank_capacity, 0)) * 100, 1) as percentage,
                station_id
             FROM pumps
             WHERE station_id = ANY($1::uuid[])
               AND is_active = true
               AND (current_fuel_level / NULLIF(tank_capacity, 0)) * 100 < 20`,
            [stationIds]
        );

        // Get station names for alerts
        const stationMap = {};
        if (user.role === 'owner' && stationIds.length > 1) {
            const namesResult = await pool.query(
                'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
                [stationIds]
            );
            namesResult.rows.forEach(row => {
                stationMap[row.id] = row.name;
            });
        }

        fuelResult.rows.forEach(p => {
            const stationName = stationMap[p.station_id] ? ` [${stationMap[p.station_id]}]` : '';
            alerts.push(
                `${p.pump_number} fuel level low (${p.percentage}%)${stationName}`
            );
        });

        // ── 2. Pending Shift Reports ──────────────────────
        const shiftResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM shift_reports
             WHERE station_id = ANY($1::uuid[]) AND status = 'pending'`,
            [stationIds]
        );

        const pendingShifts = parseInt(shiftResult.rows[0].count || 0);
        if (pendingShifts > 0) {
            alerts.push(`${pendingShifts} shift report(s) pending approval`);
        }

        // ── 3. Pending Employee Approvals ──────────────────
        const empResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM employee_invitations
             WHERE station_id = ANY($1::uuid[]) AND status = 'pending'`,
            [stationIds]
        );

        const pendingEmployees = parseInt(empResult.rows[0].count || 0);
        if (pendingEmployees > 0) {
            alerts.push(`${pendingEmployees} employee(s) pending approval`);
        }

        res.json({
            success: true,
            data: {
                alerts: alerts,
                pending_reports: pendingShifts,
                stations_covered: stationIds.length,
                is_owner: user.role === 'owner'
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
        const user = req.user;
        const { period = 'week', station_id } = req.query;
        
        let stationIds = await getStationIds(user);
        
        if (user.role === 'owner' && station_id) {
            const check = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2',
                [station_id, user.userId]
            );
            if (check.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not own this station'
                });
            }
            stationIds = [station_id];
        }

        if (stationIds.length === 0) {
            return res.json({
                success: true,
                data: {
                    daily_sales: [],
                    payment_breakdown: [],
                    fuel_breakdown: [],
                    hourly_sales: [],
                    top_attendants: [],
                    station_breakdown: [],
                    summary: {
                        total_transactions: 0,
                        total_sales: 0,
                        total_liters: 0,
                        average_sale: 0
                    },
                    chart_data: {
                        labels: [],
                        sales: [],
                        liters: [],
                        transactions: []
                    },
                    is_owner: user.role === 'owner'
                }
            });
        }

        // ── Date range calculation ──────────────────────────
        let startDate;
        const now = new Date();
        
        switch(period) {
            case 'week':
                startDate = new Date(now);
                startDate.setDate(now.getDate() - 7);
                break;
            case 'month':
                startDate = new Date(now);
                startDate.setMonth(now.getMonth() - 1);
                break;
            case 'year':
                startDate = new Date(now);
                startDate.setFullYear(now.getFullYear() - 1);
                break;
            default:
                startDate = new Date(now);
                startDate.setDate(now.getDate() - 7);
        }

        // ── 1. Daily Sales Data ──────────────────────────────
        const dailySalesResult = await pool.query(
            `SELECT 
                DATE(created_at) as date,
                COUNT(*) as transaction_count,
                SUM(amount) as total_sales,
                SUM(quantity) as total_liters,
                AVG(amount) as avg_transaction,
                station_id
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND created_at >= $2
               AND status = 'completed'
             GROUP BY DATE(created_at), station_id
             ORDER BY date ASC`,
            [stationIds, startDate]
        );

        // ── 2. Payment Method Breakdown ──────────────────────
        const paymentResult = await pool.query(
            `SELECT 
                payment_method,
                COUNT(*) as count,
                SUM(amount) as total_amount,
                station_id
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND created_at >= $2
               AND status = 'completed'
             GROUP BY payment_method, station_id`,
            [stationIds, startDate]
        );

        // ── 3. Fuel Type Breakdown ───────────────────────────
        const fuelResult = await pool.query(
            `SELECT 
                fuel_type,
                COUNT(*) as count,
                SUM(quantity) as total_liters,
                SUM(amount) as total_amount,
                station_id
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND created_at >= $2
               AND status = 'completed'
             GROUP BY fuel_type, station_id`,
            [stationIds, startDate]
        );

        // ── 4. Hourly Sales ──────────────────────────────────
        const hourlyResult = await pool.query(
            `SELECT 
                EXTRACT(HOUR FROM created_at) as hour,
                COUNT(*) as transactions,
                SUM(amount) as total_amount,
                station_id
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND created_at >= $2
               AND status = 'completed'
             GROUP BY EXTRACT(HOUR FROM created_at), station_id
             ORDER BY hour ASC`,
            [stationIds, startDate]
        );

        // ── 5. Top Attendants ────────────────────────────────
        const attendantResult = await pool.query(
            `SELECT 
                u.id as attendant_id,
                u.username,
                u.full_name,
                COUNT(t.id) as transactions,
                SUM(t.amount) as total_sales,
                t.station_id
             FROM transactions t
             JOIN users u ON t.attendant_id = u.id
             WHERE t.station_id = ANY($1::uuid[])
               AND t.created_at >= $2
               AND t.status = 'completed'
             GROUP BY u.id, u.username, u.full_name, t.station_id
             ORDER BY total_sales DESC
             LIMIT 10`,
            [stationIds, startDate]
        );

        // ── 6. Summary Stats ─────────────────────────────────
        const summaryResult = await pool.query(
            `SELECT 
                COUNT(*) as total_transactions,
                SUM(amount) as total_sales,
                SUM(quantity) as total_liters,
                AVG(amount) as average_sale,
                COUNT(DISTINCT station_id) as stations_with_sales
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND created_at >= $2
               AND status = 'completed'`,
            [stationIds, startDate]
        );

        // ── 7. Station Breakdown (for owners) ────────────────
        let stationBreakdown = [];
        if (user.role === 'owner' && stationIds.length > 1) {
            const breakdownResult = await pool.query(
                `SELECT 
                    s.id as station_id,
                    s.name as station_name,
                    COUNT(t.id) as transaction_count,
                    SUM(t.amount) as total_sales,
                    SUM(t.quantity) as total_liters
                 FROM stations s
                 LEFT JOIN transactions t ON t.station_id = s.id 
                    AND t.created_at >= $2
                    AND t.status = 'completed'
                 WHERE s.id = ANY($1::uuid[])
                 GROUP BY s.id, s.name
                 ORDER BY total_sales DESC NULLS LAST`,
                [stationIds, startDate]
            );
            stationBreakdown = breakdownResult.rows;
        }

        // ── Aggregate for Charts ─────────────────────────────
        const aggregatedDaily = {};
        dailySalesResult.rows.forEach(row => {
            const date = row.date.toISOString().split('T')[0];
            if (!aggregatedDaily[date]) {
                aggregatedDaily[date] = { 
                    date, 
                    transaction_count: 0, 
                    total_sales: 0, 
                    total_liters: 0
                };
            }
            aggregatedDaily[date].transaction_count += parseInt(row.transaction_count);
            aggregatedDaily[date].total_sales += parseFloat(row.total_sales);
            aggregatedDaily[date].total_liters += parseFloat(row.total_liters);
        });

        // ── Fill missing dates ──────────────────────────────
        const labels = [];
        const sales = [];
        const liters = [];
        const transactions = [];
        const today = new Date();
        
        for (let i = 6; i >= 0; i--) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);
            const dateStr = date.toISOString().split('T')[0];
            labels.push(dateStr);
            
            const found = aggregatedDaily[dateStr];
            sales.push(found ? found.total_sales : 0);
            liters.push(found ? found.total_liters : 0);
            transactions.push(found ? found.transaction_count : 0);
        }

        // ── Get station names ─────────────────────────────────
        let stationNames = [];
        if (user.role === 'owner' && stationIds.length > 1) {
            const namesResult = await pool.query(
                'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
                [stationIds]
            );
            stationNames = namesResult.rows;
        }

        res.json({
            success: true,
            data: {
                period,
                is_owner: user.role === 'owner',
                stations_covered: stationIds.length,
                stations: stationNames,
                summary: summaryResult.rows[0] || {
                    total_transactions: 0,
                    total_sales: 0,
                    total_liters: 0,
                    average_sale: 0,
                    stations_with_sales: 0
                },
                daily_sales: dailySalesResult.rows,
                payment_breakdown: paymentResult.rows,
                fuel_breakdown: fuelResult.rows,
                hourly_sales: hourlyResult.rows,
                top_attendants: attendantResult.rows,
                station_breakdown: stationBreakdown,
                chart_data: {
                    labels: labels,
                    sales: sales,
                    liters: liters,
                    transactions: transactions
                }
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
        const user = req.user;
        const { station_id } = req.query;

        let stationIds = await getStationIds(user);
        
        if (user.role === 'owner' && station_id) {
            const check = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2',
                [station_id, user.userId]
            );
            if (check.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not own this station'
                });
            }
            stationIds = [station_id];
        }

        if (stationIds.length === 0) {
            return res.json({
                success: true,
                data: {
                    activeAttendants: 0,
                    pendingReports: 0,
                    lowFuelPumps: 0,
                    totalSales: 0,
                    stations_covered: 0
                }
            });
        }

        // ── Active Attendants ──────────────────────────────
        const attendantResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM employees
             WHERE station_id = ANY($1::uuid[])
               AND employee_role = 'attendant' 
               AND status = 'active'`,
            [stationIds]
        );

        // ── Pending Reports ────────────────────────────────
        const pendingResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM shift_reports
             WHERE station_id = ANY($1::uuid[]) AND status = 'pending'`,
            [stationIds]
        );

        // ── Low Fuel Pumps ──────────────────────────────────
        const fuelResult = await pool.query(
            `SELECT COUNT(*) as count
             FROM pumps
             WHERE station_id = ANY($1::uuid[])
               AND is_active = true
               AND (current_fuel_level / NULLIF(tank_capacity, 0)) * 100 < 20`,
            [stationIds]
        );

        // ── Today's Sales ──────────────────────────────────
        const salesResult = await pool.query(
            `SELECT COALESCE(SUM(amount), 0) as total
             FROM transactions
             WHERE station_id = ANY($1::uuid[])
               AND DATE(created_at) = CURRENT_DATE 
               AND status = 'completed'`,
            [stationIds]
        );

        // ── Station names (for owners) ─────────────────────
        let stationNames = [];
        if (user.role === 'owner' && stationIds.length > 1) {
            const namesResult = await pool.query(
                'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
                [stationIds]
            );
            stationNames = namesResult.rows;
        }

        res.json({
            success: true,
            data: {
                activeAttendants: parseInt(attendantResult.rows[0].count || 0),
                pendingReports: parseInt(pendingResult.rows[0].count || 0),
                lowFuelPumps: parseInt(fuelResult.rows[0].count || 0),
                totalSales: parseFloat(salesResult.rows[0].total || 0),
                stations_covered: stationIds.length,
                stations: stationNames,
                is_owner: user.role === 'owner'
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

/**
 * GET /api/manager/stations
 * For owners: Get list of all their stations with stats
 */
const getStationsForAnalytics = async (req, res) => {
    try {
        const user = req.user;
        
        if (user.role !== 'owner') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Owner only.'
            });
        }

        const stations = await pool.query(
            `SELECT 
                s.id,
                s.name,
                s.location,
                s.status,
                s.created_at,
                (SELECT COUNT(*) FROM transactions t WHERE t.station_id = s.id AND t.status = 'completed') as total_transactions,
                (SELECT COALESCE(SUM(amount), 0) FROM transactions t WHERE t.station_id = s.id AND t.status = 'completed') as total_sales,
                (SELECT COALESCE(SUM(amount), 0) FROM transactions t WHERE t.station_id = s.id AND t.status = 'completed' AND DATE(t.created_at) = CURRENT_DATE) as today_sales,
                (SELECT COUNT(*) FROM pumps p WHERE p.station_id = s.id AND p.is_active = true AND p.status = 'active') as active_pumps,
                (SELECT COUNT(*) FROM employees e WHERE e.station_id = s.id AND e.employee_role = 'attendant' AND e.status = 'active') as active_attendants
            FROM stations s
            WHERE s.owner_id = $1
            ORDER BY s.name ASC`,
            [user.userId]
        );

        res.json({
            success: true,
            data: stations.rows
        });

    } catch (err) {
        console.error('getStationsForAnalytics error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load stations'
        });
    }
};

module.exports = {
    getManagerDashboard,
    getAlerts,
    getSalesAnalytics,
    getQuickStats,
    getStationsForAnalytics
};