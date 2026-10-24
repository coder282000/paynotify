// src/controllers/expenseController.js
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
 * GET /api/expenses
 * List expenses (manager/owner only)
 */
const getExpenses = async (req, res) => {
    try {
        const user = req.user;
        const { 
            category, 
            station_id,
            start_date, 
            end_date, 
            limit = 50, 
            offset = 0,
            sort_by = 'expense_date',
            sort_order = 'DESC'
        } = req.query;

        // ── Get station IDs ──────────────────────────────────
        let stationIds = await getStationIds(user);
        
        // If owner and station_id provided, filter to that station
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
                    expenses: [],
                    pagination: { total: 0, limit: parseInt(limit), offset: parseInt(offset) },
                    summary: { 
                        by_category: [], 
                        monthly_trend: [], 
                        station_breakdown: [],
                        total_expenses: 0, 
                        total_count: 0 
                    },
                    stations: [],
                    is_owner: user.role === 'owner'
                }
            });
        }

        // ── Build query ─────────────────────────────────────────
        let query = `
            SELECT 
                e.id,
                e.category,
                e.amount,
                e.description,
                e.expense_date,
                e.vendor_name,
                e.payment_method,
                e.reference_number,
                e.created_by,
                e.is_recurring,
                e.recurring_interval_days,
                e.notes,
                e.created_at,
                e.station_id,
                s.name as station_name,
                u.full_name as created_by_name
            FROM expenses e
            LEFT JOIN stations s ON e.station_id = s.id
            LEFT JOIN users u ON e.created_by = u.id
            WHERE e.station_id = ANY($1::uuid[])
        `;

        const params = [stationIds];
        let paramCount = 2;

        // ── Category filter ──────────────────────────────────
        if (category) {
            const validCategories = ['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                                     'rent', 'supplies', 'marketing', 'insurance', 'other'];
            if (!validCategories.includes(category)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid category. Must be one of: ${validCategories.join(', ')}`
                });
            }
            query += ` AND e.category = $${paramCount}`;
            params.push(category);
            paramCount++;
        }

        // ── Date filters ─────────────────────────────────────
        if (start_date) {
            query += ` AND DATE(e.expense_date) >= $${paramCount}`;
            params.push(start_date);
            paramCount++;
        }

        if (end_date) {
            query += ` AND DATE(e.expense_date) <= $${paramCount}`;
            params.push(end_date);
            paramCount++;
        }

        // ── Sort and paginate ───────────────────────────────
        const validSortColumns = ['expense_date', 'amount', 'category', 'station_name'];
        const sortColumn = validSortColumns.includes(sort_by) ? sort_by : 'expense_date';
        const order = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
        
        query += ` ORDER BY ${sortColumn} ${order}`;
        query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await pool.query(query, params);

        // ── Get total count ──────────────────────────────────
        let countQuery = 'SELECT COUNT(*) as total FROM expenses e WHERE e.station_id = ANY($1::uuid[])';
        const countParams = [stationIds];
        let countIndex = 2;

        if (category) {
            countQuery += ` AND e.category = $${countIndex}`;
            countParams.push(category);
            countIndex++;
        }

        if (start_date) {
            countQuery += ` AND DATE(e.expense_date) >= $${countIndex}`;
            countParams.push(start_date);
            countIndex++;
        }

        if (end_date) {
            countQuery += ` AND DATE(e.expense_date) <= $${countIndex}`;
            countParams.push(end_date);
            countIndex++;
        }

        const countResult = await pool.query(countQuery, countParams);

        // ── Summary by category ─────────────────────────────
        const summaryQuery = `
            SELECT 
                e.category,
                COALESCE(SUM(e.amount), 0) as total,
                COUNT(*) as count,
                e.station_id
            FROM expenses e
            WHERE e.station_id = ANY($1::uuid[])
        `;
        const summaryParams = [stationIds];
        let summaryIndex = 2;

        if (start_date) {
            summaryQuery += ` AND DATE(e.expense_date) >= $${summaryIndex}`;
            summaryParams.push(start_date);
            summaryIndex++;
        }

        if (end_date) {
            summaryQuery += ` AND DATE(e.expense_date) <= $${summaryIndex}`;
            summaryParams.push(end_date);
            summaryIndex++;
        }

        const summaryResult = await pool.query(summaryQuery, summaryParams);

        // ── Monthly trend ────────────────────────────────────
        const trendQuery = `
            SELECT 
                DATE_TRUNC('month', e.expense_date) as month,
                COALESCE(SUM(e.amount), 0) as total,
                COUNT(*) as count,
                e.station_id
            FROM expenses e
            WHERE e.station_id = ANY($1::uuid[])
                AND e.expense_date >= NOW() - INTERVAL '12 months'
        `;
        const trendParams = [stationIds];
        let trendIndex = 2;

        if (start_date) {
            trendQuery += ` AND DATE(e.expense_date) >= $${trendIndex}`;
            trendParams.push(start_date);
            trendIndex++;
        }

        if (end_date) {
            trendQuery += ` AND DATE(e.expense_date) <= $${trendIndex}`;
            trendParams.push(end_date);
            trendIndex++;
        }

        const trendResult = await pool.query(trendQuery, trendParams);

        // ── Station breakdown (for owners) ──────────────────
        let stationBreakdown = [];
        if (user.role === 'owner' && stationIds.length > 1) {
            const breakdownQuery = `
                SELECT 
                    s.id as station_id,
                    s.name as station_name,
                    COUNT(e.id) as expense_count,
                    COALESCE(SUM(e.amount), 0) as total_expenses
                FROM stations s
                LEFT JOIN expenses e ON e.station_id = s.id
                WHERE s.id = ANY($1::uuid[])
            `;
            const breakdownParams = [stationIds];
            let breakdownIndex = 2;

            if (start_date) {
                breakdownQuery += ` AND DATE(e.expense_date) >= $${breakdownIndex}`;
                breakdownParams.push(start_date);
                breakdownIndex++;
            }

            if (end_date) {
                breakdownQuery += ` AND DATE(e.expense_date) <= $${breakdownIndex}`;
                breakdownParams.push(end_date);
                breakdownIndex++;
            }

            breakdownQuery += ` GROUP BY s.id, s.name ORDER BY total_expenses DESC`;
            const breakdownResult = await pool.query(breakdownQuery, breakdownParams);
            stationBreakdown = breakdownResult.rows;
        }

        // ── Get station names ────────────────────────────────
        const stationNames = await pool.query(
            'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
            [stationIds]
        );

        // ── Calculate totals ─────────────────────────────────
        const totals = summaryResult.rows.reduce((acc, row) => ({
            total_expenses: acc.total_expenses + parseFloat(row.total || 0),
            total_count: acc.total_count + parseInt(row.count || 0)
        }), { total_expenses: 0, total_count: 0 });

        res.json({
            success: true,
            data: {
                expenses: result.rows.map(row => ({
                    id: row.id,
                    category: row.category,
                    amount: parseFloat(row.amount || 0),
                    description: row.description,
                    expenseDate: row.expense_date,
                    vendorName: row.vendor_name,
                    paymentMethod: row.payment_method,
                    referenceNumber: row.reference_number,
                    createdBy: row.created_by,
                    createdByName: row.created_by_name,
                    isRecurring: row.is_recurring,
                    recurringIntervalDays: row.recurring_interval_days,
                    notes: row.notes,
                    createdAt: row.created_at,
                    stationId: row.station_id,
                    stationName: row.station_name
                })),
                stations: stationNames.rows,
                pagination: {
                    total: parseInt(countResult.rows[0].total || 0),
                    limit: parseInt(limit),
                    offset: parseInt(offset)
                },
                summary: {
                    by_category: summaryResult.rows.map(row => ({
                        category: row.category,
                        total: parseFloat(row.total || 0),
                        count: parseInt(row.count || 0)
                    })),
                    monthly_trend: trendResult.rows.map(row => ({
                        month: row.month,
                        total: parseFloat(row.total || 0),
                        count: parseInt(row.count || 0)
                    })),
                    station_breakdown: stationBreakdown,
                    total_expenses: totals.total_expenses,
                    total_count: totals.total_count
                },
                is_owner: user.role === 'owner',
                stations_covered: stationIds.length
            }
        });

    } catch (err) {
        console.error('Get expenses error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load expenses'
        });
    }
};

/**
 * POST /api/expenses
 * Create new expense
 */
const createExpense = async (req, res) => {
    try {
        const user = req.user;
        const {
            category,
            amount,
            description,
            expense_date,
            vendor_name,
            payment_method,
            reference_number,
            is_recurring,
            recurring_interval_days,
            notes,
            station_id // For owners to specify which station
        } = req.body;

        // ── Validate ────────────────────────────────────────────
        const validCategories = ['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                                 'rent', 'supplies', 'marketing', 'insurance', 'other'];
        
        if (!category || !validCategories.includes(category)) {
            return res.status(400).json({
                success: false,
                message: `Invalid category. Must be one of: ${validCategories.join(', ')}`
            });
        }

        if (!amount || amount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Valid amount is required'
            });
        }

        if (!description) {
            return res.status(400).json({
                success: false,
                message: 'Description is required'
            });
        }

        // ── Determine station ──────────────────────────────────
        let targetStationId;

        if (user.role === 'owner') {
            if (!station_id) {
                return res.status(400).json({
                    success: false,
                    message: 'Station ID required for owner'
                });
            }
            // Verify station belongs to owner
            const stationCheck = await pool.query(
                'SELECT id FROM stations WHERE id = $1 AND owner_id = $2 AND is_active = true',
                [station_id, user.userId]
            );
            if (stationCheck.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not own this station or station is inactive'
                });
            }
            targetStationId = station_id;
        } else {
            // Manager - get their station
            const stationResult = await pool.query(
                `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
                [user.userId]
            );
            if (stationResult.rows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No station assigned to this manager'
                });
            }
            targetStationId = stationResult.rows[0].id;
        }

        // ── Create expense ──────────────────────────────────────
        const result = await pool.query(
            `INSERT INTO expenses 
             (station_id, category, amount, description, expense_date, vendor_name, 
              payment_method, reference_number, created_by, is_recurring, 
              recurring_interval_days, notes)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
             RETURNING *`,
            [targetStationId, category, parseFloat(amount), description, 
             expense_date || new Date().toISOString().split('T')[0],
             vendor_name || null, payment_method || null, reference_number || null,
             user.userId, is_recurring || false, recurring_interval_days || null, notes || null]
        );

        // ── Log the action ──────────────────────────────────────
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'EXPENSE_CREATED', $2, $3)`,
            [user.userId, `Expense created: ${category} - KES ${amount} - ${description}`, targetStationId]
        );

        res.status(201).json({
            success: true,
            message: 'Expense recorded successfully',
            data: {
                ...result.rows[0],
                station_id: targetStationId
            }
        });

    } catch (err) {
        console.error('Create expense error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to create expense'
        });
    }
};

/**
 * PUT /api/expenses/:id
 * Update expense
 */
const updateExpense = async (req, res) => {
    try {
        const user = req.user;
        const { id } = req.params;
        const {
            category,
            amount,
            description,
            expense_date,
            vendor_name,
            payment_method,
            reference_number,
            is_recurring,
            recurring_interval_days,
            notes
        } = req.body;

        // ── Check expense exists and user has access ──────────
        let accessCondition = '';
        let accessParams = [];

        if (user.role === 'owner') {
            // Owner can update any expense in their stations
            accessCondition = `AND e.station_id IN (SELECT id FROM stations WHERE owner_id = $2 AND is_active = true)`;
            accessParams = [id, user.userId];
        } else {
            // Manager only their station
            accessCondition = `AND e.station_id = $2`;
            const stationResult = await pool.query(
                `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
                [user.userId]
            );
            if (stationResult.rows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No station assigned to this manager'
                });
            }
            accessParams = [id, stationResult.rows[0].id];
        }

        // Check if expense exists and user has access
        const checkResult = await pool.query(
            `SELECT e.id, e.station_id FROM expenses e WHERE e.id = $1 ${accessCondition}`,
            accessParams
        );

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Expense not found or access denied'
            });
        }

        // ── Build update query ──────────────────────────────────
        const updates = [];
        const values = [];
        let paramCount = 1;

        if (category !== undefined) {
            const validCategories = ['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                                     'rent', 'supplies', 'marketing', 'insurance', 'other'];
            if (!validCategories.includes(category)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid category. Must be one of: ${validCategories.join(', ')}`
                });
            }
            updates.push(`category = $${paramCount}`);
            values.push(category);
            paramCount++;
        }

        if (amount !== undefined) {
            if (amount <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Amount must be greater than 0'
                });
            }
            updates.push(`amount = $${paramCount}`);
            values.push(parseFloat(amount));
            paramCount++;
        }

        if (description !== undefined) {
            updates.push(`description = $${paramCount}`);
            values.push(description);
            paramCount++;
        }

        if (expense_date !== undefined) {
            updates.push(`expense_date = $${paramCount}`);
            values.push(expense_date);
            paramCount++;
        }

        if (vendor_name !== undefined) {
            updates.push(`vendor_name = $${paramCount}`);
            values.push(vendor_name || null);
            paramCount++;
        }

        if (payment_method !== undefined) {
            updates.push(`payment_method = $${paramCount}`);
            values.push(payment_method || null);
            paramCount++;
        }

        if (reference_number !== undefined) {
            updates.push(`reference_number = $${paramCount}`);
            values.push(reference_number || null);
            paramCount++;
        }

        if (is_recurring !== undefined) {
            updates.push(`is_recurring = $${paramCount}`);
            values.push(is_recurring);
            paramCount++;
        }

        if (recurring_interval_days !== undefined) {
            updates.push(`recurring_interval_days = $${paramCount}`);
            values.push(recurring_interval_days || null);
            paramCount++;
        }

        if (notes !== undefined) {
            updates.push(`notes = $${paramCount}`);
            values.push(notes || null);
            paramCount++;
        }

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No fields to update'
            });
        }

        values.push(id);
        const query = `UPDATE expenses SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;
        const result = await pool.query(query, values);

        // ── Log the action ──────────────────────────────────────
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'EXPENSE_UPDATED', $2, $3)`,
            [user.userId, `Expense ${id} updated`, checkResult.rows[0].station_id]
        );

        res.json({
            success: true,
            message: 'Expense updated successfully',
            data: result.rows[0]
        });

    } catch (err) {
        console.error('Update expense error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to update expense'
        });
    }
};

/**
 * DELETE /api/expenses/:id
 * Delete expense
 */
const deleteExpense = async (req, res) => {
    try {
        const user = req.user;
        const { id } = req.params;

        // ── Check expense exists and user has access ──────────
        let accessCondition = '';
        let accessParams = [];

        if (user.role === 'owner') {
            accessCondition = `AND station_id IN (SELECT id FROM stations WHERE owner_id = $2 AND is_active = true)`;
            accessParams = [id, user.userId];
        } else {
            accessCondition = `AND station_id = $2`;
            const stationResult = await pool.query(
                `SELECT id FROM stations WHERE manager_id = $1 AND is_active = true`,
                [user.userId]
            );
            if (stationResult.rows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No station assigned to this manager'
                });
            }
            accessParams = [id, stationResult.rows[0].id];
        }

        // Delete expense
        const result = await pool.query(
            `DELETE FROM expenses WHERE id = $1 ${accessCondition} RETURNING id, station_id`,
            accessParams
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Expense not found or access denied'
            });
        }

        // ── Log the action ──────────────────────────────────────
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'EXPENSE_DELETED', $2, $3)`,
            [user.userId, `Expense ${id} deleted`, result.rows[0].station_id]
        );

        res.json({
            success: true,
            message: 'Expense deleted successfully'
        });

    } catch (err) {
        console.error('Delete expense error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to delete expense'
        });
    }
};

/**
 * GET /api/expenses/categories
 * Get expense summary by category
 */
const getExpenseCategories = async (req, res) => {
    try {
        const user = req.user;
        const { start_date, end_date, station_id } = req.query;

        // ── Get station IDs ──────────────────────────────────
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
                data: [],
                stations_covered: 0,
                is_owner: user.role === 'owner'
            });
        }

        let query = `
            SELECT 
                category,
                COALESCE(SUM(amount), 0) as total,
                COUNT(*) as count,
                station_id
            FROM expenses
            WHERE station_id = ANY($1::uuid[])
        `;

        const params = [stationIds];
        let paramCount = 2;

        if (start_date) {
            query += ` AND DATE(expense_date) >= $${paramCount}`;
            params.push(start_date);
            paramCount++;
        }

        if (end_date) {
            query += ` AND DATE(expense_date) <= $${paramCount}`;
            params.push(end_date);
            paramCount++;
        }

        query += ` GROUP BY category, station_id ORDER BY category`;

        const result = await pool.query(query, params);

        // ── Get station names ──────────────────────────────────
        const stationNames = await pool.query(
            'SELECT id, name FROM stations WHERE id = ANY($1::uuid[])',
            [stationIds]
        );

        // ── Aggregate by category across stations ──────────────
        const categoryMap = {};
        result.rows.forEach(row => {
            if (!categoryMap[row.category]) {
                categoryMap[row.category] = {
                    category: row.category,
                    total: 0,
                    count: 0,
                    stations: []
                };
            }
            categoryMap[row.category].total += parseFloat(row.total || 0);
            categoryMap[row.category].count += parseInt(row.count || 0);
            categoryMap[row.category].stations.push({
                station_id: row.station_id,
                total: parseFloat(row.total || 0),
                count: parseInt(row.count || 0)
            });
        });

        const categories = Object.values(categoryMap).map(cat => ({
            ...cat,
            total: cat.total,
            count: cat.count
        }));

        res.json({
            success: true,
            data: categories,
            stations: stationNames.rows,
            stations_covered: stationIds.length,
            is_owner: user.role === 'owner'
        });

    } catch (err) {
        console.error('Get expense categories error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load expense categories'
        });
    }
};

/**
 * GET /api/expenses/stations
 * For owners: Get expense summary by station
 */
const getExpenseStations = async (req, res) => {
    try {
        const user = req.user;
        
        if (user.role !== 'owner') {
            return res.status(403).json({
                success: false,
                message: 'Access denied. Owner only.'
            });
        }

        const { start_date, end_date } = req.query;

        let query = `
            SELECT 
                s.id as station_id,
                s.name as station_name,
                COUNT(e.id) as expense_count,
                COALESCE(SUM(e.amount), 0) as total_expenses,
                COALESCE(AVG(e.amount), 0) as avg_expense
            FROM stations s
            LEFT JOIN expenses e ON e.station_id = s.id
            WHERE s.owner_id = $1
        `;

        const params = [user.userId];
        let paramCount = 2;

        if (start_date) {
            query += ` AND DATE(e.expense_date) >= $${paramCount}`;
            params.push(start_date);
            paramCount++;
        }

        if (end_date) {
            query += ` AND DATE(e.expense_date) <= $${paramCount}`;
            params.push(end_date);
            paramCount++;
        }

        query += ` GROUP BY s.id, s.name ORDER BY total_expenses DESC`;

        const result = await pool.query(query, params);

        // ── Get total across all stations ──────────────────────
        const totalQuery = `
            SELECT 
                COUNT(*) as total_count,
                COALESCE(SUM(amount), 0) as total_amount
            FROM expenses e
            WHERE e.station_id IN (SELECT id FROM stations WHERE owner_id = $1)
        `;
        const totalParams = [user.userId];
        let totalIndex = 2;

        if (start_date) {
            totalQuery += ` AND DATE(e.expense_date) >= $${totalIndex}`;
            totalParams.push(start_date);
            totalIndex++;
        }

        if (end_date) {
            totalQuery += ` AND DATE(e.expense_date) <= $${totalIndex}`;
            totalParams.push(end_date);
            totalIndex++;
        }

        const totalResult = await pool.query(totalQuery, totalParams);

        res.json({
            success: true,
            data: {
                stations: result.rows.map(row => ({
                    station_id: row.station_id,
                    station_name: row.station_name,
                    expense_count: parseInt(row.expense_count || 0),
                    total_expenses: parseFloat(row.total_expenses || 0),
                    avg_expense: parseFloat(row.avg_expense || 0)
                })),
                totals: {
                    total_expenses: parseFloat(totalResult.rows[0].total_amount || 0),
                    total_count: parseInt(totalResult.rows[0].total_count || 0)
                }
            }
        });

    } catch (err) {
        console.error('Get expense stations error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load expense stations'
        });
    }
};

module.exports = {
    getExpenses,
    createExpense,
    updateExpense,
    deleteExpense,
    getExpenseCategories,
    getExpenseStations
};