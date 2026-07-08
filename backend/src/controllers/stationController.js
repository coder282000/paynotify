// src/controllers/stationController.js
const pool = require('../config/database');

/**
 * GET /api/stations
 * Get all stations for the authenticated owner/manager
 * Owners see all their stations, managers see assigned station
 */
const getStations = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;

        // First, get the basic station data
        let query = `
            SELECT 
                s.id,
                s.owner_id,
                s.station_name,
                s.station_code,
                s.location,
                s.city,
                s.county,
                s.phone,
                s.email,
                s.manager_id,
                s.paybill_number,
                s.till_number,
                s.is_active,
                s.status,
                s.created_at,
                s.updated_at,
                u.full_name as manager_name
            FROM stations s
            LEFT JOIN users u ON s.manager_id = u.id
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        // Role-based filtering
        if (userRole === 'owner') {
            query += ` AND s.owner_id = $${paramCount}`;
            params.push(userId);
            paramCount++;
        } else if (userRole === 'manager') {
            query += ` AND s.manager_id = $${paramCount}`;
            params.push(userId);
            paramCount++;
        } else {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Only owners and managers can view stations.'
            });
        }

        query += ` ORDER BY s.created_at DESC`;

        const result = await pool.query(query, params);

        // If no stations, return early
        if (result.rows.length === 0) {
            return res.json({
                success: true,
                data: [],
                count: 0
            });
        }

        // Get pump counts and sales separately for each station
        const stationIds = result.rows.map(s => s.id);
        const placeholders = stationIds.map((_, i) => `$${i + 1}`).join(',');

        // Get pump counts
        const pumpCounts = await pool.query(`
            SELECT 
                station_id,
                COUNT(*) as total_pumps,
                COUNT(CASE WHEN status = 'active' THEN 1 END) as active_pumps
            FROM pumps
            WHERE station_id IN (${placeholders})
            GROUP BY station_id
        `, stationIds);

        // Get today's sales
        const salesData = await pool.query(`
            SELECT 
                station_id,
                COALESCE(SUM(amount), 0) as total_sales
            FROM transactions
            WHERE station_id IN (${placeholders}) 
                AND DATE(created_at) = CURRENT_DATE 
                AND status = 'completed'
            GROUP BY station_id
        `, stationIds);

        // Combine the data
        const pumpMap = {};
        pumpCounts.rows.forEach(row => {
            pumpMap[row.station_id] = {
                totalPumps: parseInt(row.total_pumps),
                activePumps: parseInt(row.active_pumps)
            };
        });

        const salesMap = {};
        salesData.rows.forEach(row => {
            salesMap[row.station_id] = parseFloat(row.total_sales);
        });

        const stations = result.rows.map(station => ({
            id: station.id,
            ownerId: station.owner_id,
            stationName: station.station_name,
            stationCode: station.station_code,
            location: station.location,
            city: station.city,
            county: station.county,
            phone: station.phone,
            email: station.email,
            managerId: station.manager_id,
            managerName: station.manager_name,
            paybillNumber: station.paybill_number,
            tillNumber: station.till_number,
            isActive: station.is_active,
            status: station.status,
            totalPumps: pumpMap[station.id]?.totalPumps || 0,
            activePumps: pumpMap[station.id]?.activePumps || 0,
            todaySales: salesMap[station.id] || 0,
            createdAt: station.created_at,
            updatedAt: station.updated_at
        }));

        res.json({
            success: true,
            data: stations,
            count: stations.length
        });

    } catch (err) {
        console.error('Get stations error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve stations'
        });
    }
};

/**
 * GET /api/stations/:id
 * Get single station details with analytics
 */
const getStationById = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid station ID'
            });
        }

        const stationResult = await pool.query(
            `SELECT 
                s.id,
                s.owner_id,
                s.station_name,
                s.station_code,
                s.location,
                s.city,
                s.county,
                s.phone,
                s.email,
                s.manager_id,
                s.paybill_number,
                s.till_number,
                s.opening_time,
                s.closing_time,
                s.is_24_hours,
                s.is_active,
                s.status,
                s.created_at,
                s.updated_at,
                u.full_name as manager_name,
                u.phone as manager_phone,
                u.email as manager_email
            FROM stations s
            LEFT JOIN users u ON s.manager_id = u.id
            WHERE s.id = $1`,
            [id]
        );

        if (stationResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Station not found'
            });
        }

        const station = stationResult.rows[0];

        if (userRole === 'owner' && station.owner_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You do not own this station.'
            });
        }

        if (userRole === 'manager' && station.manager_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You do not manage this station.'
            });
        }

        const pumpsResult = await pool.query(
            `SELECT id, pump_number, fuel_type, status, price_per_liter, current_fuel_level
             FROM pumps WHERE station_id = $1 ORDER BY pump_number`,
            [id]
        );

        const summaryResult = await pool.query(
            `SELECT 
                COALESCE(SUM(amount), 0) as total_sales,
                COALESCE(SUM(CASE WHEN payment_type = 'cash' THEN amount ELSE 0 END), 0) as cash_sales,
                COALESCE(SUM(CASE WHEN payment_type = 'card' THEN amount ELSE 0 END), 0) as card_sales,
                COALESCE(SUM(CASE WHEN payment_type = 'mpesa' THEN amount ELSE 0 END), 0) as mpesa_sales,
                COUNT(*) as transaction_count
             FROM transactions 
             WHERE station_id = $1 AND DATE(created_at) = CURRENT_DATE AND status = 'completed'`,
            [id]
        );

        const summary = summaryResult.rows[0];

        const staffResult = await pool.query(
            `SELECT COUNT(*) as total_staff, 
                    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_staff
             FROM employees WHERE station_id = $1`,
            [id]
        );

        const staff = staffResult.rows[0];

        res.json({
            success: true,
            data: {
                id: station.id,
                ownerId: station.owner_id,
                stationName: station.station_name,
                stationCode: station.station_code,
                location: station.location,
                city: station.city,
                county: station.county,
                phone: station.phone,
                email: station.email,
                managerId: station.manager_id,
                manager: station.manager_name ? {
                    id: station.manager_id,
                    name: station.manager_name,
                    phone: station.manager_phone,
                    email: station.manager_email
                } : null,
                paybillNumber: station.paybill_number,
                tillNumber: station.till_number,
                openingTime: station.opening_time,
                closingTime: station.closing_time,
                is24Hours: station.is_24_hours,
                isActive: station.is_active,
                status: station.status,
                createdAt: station.created_at,
                updatedAt: station.updated_at,
                todayMetrics: {
                    totalSales: parseFloat(summary.total_sales),
                    cashSales: parseFloat(summary.cash_sales),
                    cardSales: parseFloat(summary.card_sales),
                    mpesaSales: parseFloat(summary.mpesa_sales),
                    transactionCount: parseInt(summary.transaction_count)
                },
                staffMetrics: {
                    totalStaff: parseInt(staff.total_staff),
                    activeStaff: parseInt(staff.active_staff)
                },
                pumps: pumpsResult.rows.map(p => ({
                    id: p.id,
                    pumpNumber: p.pump_number,
                    fuelType: p.fuel_type,
                    status: p.status,
                    pricePerLiter: parseFloat(p.price_per_liter),
                    currentFuelLevel: parseFloat(p.current_fuel_level)
                }))
            }
        });

    } catch (err) {
        console.error('Get station by ID error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve station'
        });
    }
};

/**
 * POST /api/stations
 * Create new station (Owner only)
 */
const createStation = async (req, res) => {
    const { 
        station_name, 
        station_code, 
        location, 
        city, 
        county, 
        phone, 
        email, 
        manager_id = null,
        paybill_number = null,
        till_number = null
    } = req.body;
    const ownerId = req.user.userId;

    try {
        // Validate required fields
        if (!station_name || !station_code || !location) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: station_name, station_code, location'
            });
        }

        // Check if station code already exists
        const existing = await pool.query(
            'SELECT id FROM stations WHERE station_code = $1',
            [station_code]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Station with this code already exists'
            });
        }

        // Verify manager exists if provided
        if (manager_id) {
            const managerCheck = await pool.query(
                'SELECT id FROM users WHERE id = $1 AND role = $2',
                [manager_id, 'manager']
            );

            if (managerCheck.rows.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Invalid manager ID or user is not a manager'
                });
            }
        }

        // Create station
        const result = await pool.query(
            `INSERT INTO stations (owner_id, station_name, station_code, location, city, county, phone, email, manager_id, paybill_number, till_number, is_active)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
             RETURNING id, station_name, station_code, location, city, is_active, created_at`,
            [ownerId, station_name, station_code, location, city || null, county || null, phone || null, email || null, manager_id, paybill_number, till_number]
        );

        const station = result.rows[0];

        // ✅ FIXED: Create default station settings using key-value pairs
        const defaultSettings = [
            { key: 'currency', value: 'KES' },
            { key: 'language', value: 'en' },
            { key: 'timezone', value: 'Africa/Nairobi' },
            { key: 'opening_time', value: '08:00' },
            { key: 'closing_time', value: '20:00' },
            { key: 'is_24_hours', value: 'false' }
        ];

        for (const setting of defaultSettings) {
            await pool.query(
                `INSERT INTO station_settings (station_id, setting_key, setting_value)
                 VALUES ($1, $2, $3)`,
                [station.id, setting.key, setting.value]
            );
        }

        // Log the creation
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details)
             VALUES ($1, 'STATION_CREATED', $2)`,
            [ownerId, `Station ${station_name} (${station_code}) created`]
        );

        res.status(201).json({
            success: true,
            message: 'Station created successfully',
            data: {
                id: station.id,
                stationName: station.station_name,
                stationCode: station.station_code,
                location: station.location,
                city: station.city,
                isActive: station.is_active,
                createdAt: station.created_at
            }
        });

    } catch (err) {
        console.error('Create station error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to create station'
        });
    }
};

/**
 * PUT /api/stations/:id
 * Update station details
 */
const updateStation = async (req, res) => {
    const { id } = req.params;
    const { station_name, location, city, county, phone, email, manager_id, paybill_number, till_number, status } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        const stationCheck = await pool.query(
            'SELECT owner_id, manager_id FROM stations WHERE id = $1',
            [id]
        );

        if (stationCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Station not found'
            });
        }

        const station = stationCheck.rows[0];

        if (userRole === 'owner' && station.owner_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You do not own this station.'
            });
        }

        if (userRole === 'manager' && station.manager_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You do not manage this station.'
            });
        }

        const updates = [];
        const values = [];
        let paramCount = 1;

        if (station_name !== undefined) {
            updates.push(`station_name = $${paramCount}`);
            values.push(station_name);
            paramCount++;
        }
        if (location !== undefined) {
            updates.push(`location = $${paramCount}`);
            values.push(location);
            paramCount++;
        }
        if (city !== undefined) {
            updates.push(`city = $${paramCount}`);
            values.push(city);
            paramCount++;
        }
        if (county !== undefined) {
            updates.push(`county = $${paramCount}`);
            values.push(county);
            paramCount++;
        }
        if (phone !== undefined) {
            updates.push(`phone = $${paramCount}`);
            values.push(phone);
            paramCount++;
        }
        if (email !== undefined) {
            updates.push(`email = $${paramCount}`);
            values.push(email);
            paramCount++;
        }
        if (manager_id !== undefined) {
            updates.push(`manager_id = $${paramCount}`);
            values.push(manager_id);
            paramCount++;
        }
        if (paybill_number !== undefined) {
            updates.push(`paybill_number = $${paramCount}`);
            values.push(paybill_number);
            paramCount++;
        }
        if (till_number !== undefined) {
            updates.push(`till_number = $${paramCount}`);
            values.push(till_number);
            paramCount++;
        }
        if (status !== undefined) {
            const validStatuses = ['active', 'maintenance', 'closed', 'suspended'];
            if (!validStatuses.includes(status)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
                });
            }
            updates.push(`status = $${paramCount}`);
            values.push(status);
            paramCount++;
        }

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        updates.push(`updated_at = NOW()`);
        values.push(id);

        const query = `UPDATE stations SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;

        const result = await pool.query(query, values);

        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details)
             VALUES ($1, 'STATION_UPDATED', $2)`,
            [userId, `Station ID ${id} updated`]
        );

        const updatedStation = result.rows[0];

        res.json({
            success: true,
            message: 'Station updated successfully',
            data: {
                id: updatedStation.id,
                stationName: updatedStation.station_name,
                location: updatedStation.location,
                city: updatedStation.city,
                county: updatedStation.county,
                phone: updatedStation.phone,
                email: updatedStation.email,
                paybillNumber: updatedStation.paybill_number,
                tillNumber: updatedStation.till_number,
                status: updatedStation.status,
                updatedAt: updatedStation.updated_at
            }
        });

    } catch (err) {
        console.error('Update station error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to update station'
        });
    }
};

/**
 * GET /api/stations/:id/summary
 * Get station daily/period summary
 */
const getStationSummary = async (req, res) => {
    const { id } = req.params;
    const { start_date, end_date } = req.query;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        if (isNaN(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid station ID'
            });
        }

        const stationCheck = await pool.query(
            'SELECT owner_id, manager_id FROM stations WHERE id = $1',
            [id]
        );

        if (stationCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Station not found'
            });
        }

        const station = stationCheck.rows[0];

        if (userRole === 'owner' && station.owner_id !== userId) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }

        if (userRole === 'manager' && station.manager_id !== userId) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }

        let query = `
            SELECT 
                COUNT(*) as total_transactions,
                SUM(CASE WHEN payment_type = 'cash' THEN amount ELSE 0 END) as cash_total,
                SUM(CASE WHEN payment_type = 'card' THEN amount ELSE 0 END) as card_total,
                SUM(CASE WHEN payment_type = 'mpesa' THEN amount ELSE 0 END) as mpesa_total,
                SUM(amount) as total_sales,
                AVG(amount) as average_transaction,
                MAX(amount) as max_transaction,
                SUM(COALESCE(liters_dispensed, 0)) as total_liters
            FROM transactions
            WHERE station_id = $1 AND status = 'completed'
        `;

        const params = [id];
        let paramIndex = 2;

        if (start_date && end_date) {
            query += ` AND DATE(created_at) >= $${paramIndex} AND DATE(created_at) <= $${paramIndex + 1}`;
            params.push(start_date, end_date);
        } else {
            query += ` AND DATE(created_at) = CURRENT_DATE`;
        }

        const result = await pool.query(query, params);

        if (!result.rows || result.rows.length === 0) {
            return res.json({
                success: true,
                data: {
                    totalTransactions: 0,
                    totalSales: 0,
                    cashTotal: 0,
                    cardTotal: 0,
                    mpesaTotal: 0,
                    averageTransaction: 0,
                    maxTransaction: 0,
                    totalLiters: 0
                }
            });
        }

        const summary = result.rows[0];

        res.json({
            success: true,
            data: {
                totalTransactions: parseInt(summary.total_transactions || 0),
                totalSales: parseFloat(summary.total_sales || 0),
                cashTotal: parseFloat(summary.cash_total || 0),
                cardTotal: parseFloat(summary.card_total || 0),
                mpesaTotal: parseFloat(summary.mpesa_total || 0),
                averageTransaction: parseFloat(summary.average_transaction || 0),
                maxTransaction: parseFloat(summary.max_transaction || 0),
                totalLiters: parseFloat(summary.total_liters || 0)
            }
        });

    } catch (err) {
        console.error('Get station summary error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve station summary',
            error: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
};

/**
 * GET /api/stations/:id/performance
 * Get station performance metrics
 */
const getStationPerformance = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    try {
        const stationCheck = await pool.query(
            'SELECT owner_id FROM stations WHERE id = $1',
            [id]
        );

        if (stationCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Station not found'
            });
        }

        if (userRole === 'owner' && stationCheck.rows[0].owner_id !== userId) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }

        const perfResult = await pool.query(
            `SELECT * FROM station_performance WHERE station_id = $1`,
            [id]
        );

        let performance;
        if (perfResult.rows.length === 0) {
            await pool.query(
                `INSERT INTO station_performance (station_id) VALUES ($1)`,
                [id]
            );
            performance = {
                overallRating: 0,
                customerSatisfaction: 0,
                staffPerformance: 0,
                cleanliness: 0,
                transactionCount30d: 0,
                sales30d: 0,
                averageTransactionValue: 0,
                customerRepeatRate: 0,
                complaintsCount: 0
            };
        } else {
            const p = perfResult.rows[0];
            performance = {
                overallRating: parseFloat(p.overall_rating),
                customerSatisfaction: parseFloat(p.customer_satisfaction),
                staffPerformance: parseFloat(p.staff_performance),
                cleanliness: parseFloat(p.cleanliness_rating),
                transactionCount30d: parseInt(p.transaction_count_30d),
                sales30d: parseFloat(p.sales_30d),
                averageTransactionValue: parseFloat(p.average_transaction_value),
                customerRepeatRate: parseFloat(p.customer_repeat_rate),
                complaintsCount: parseInt(p.complaints_count)
            };
        }

        res.json({
            success: true,
            data: performance
        });

    } catch (err) {
        console.error('Get station performance error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve station performance'
        });
    }
};

module.exports = {
    getStations,
    getStationById,
    createStation,
    updateStation,
    getStationSummary,
    getStationPerformance
};