// src/controllers/expenseController.js
const pool = require('../config/database');

/**
 * GET /api/expenses
 * List expenses (manager/owner only)
 */
const getExpenses = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { category, start_date, end_date, limit = 50, offset = 0 } = req.query;

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

        // ── Build query ─────────────────────────────────────────
        let query = `
            SELECT 
                id,
                category,
                amount,
                description,
                expense_date,
                vendor_name,
                payment_method,
                reference_number,
                created_by,
                is_recurring,
                recurring_interval_days,
                notes,
                created_at
            FROM expenses
            WHERE station_id = $1
        `;

        const params = [stationId];
        let paramCount = 2;

        if (category) {
            const validCategories = ['fuelPurchase', 'salary', 'maintenance', 'utilities', 
                                     'rent', 'supplies', 'marketing', 'insurance', 'other'];
            if (!validCategories.includes(category)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid category. Must be one of: ${validCategories.join(', ')}`
                });
            }
            query += ` AND category = $${paramCount}`;
            params.push(category);
            paramCount++;
        }

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

        query += ` ORDER BY expense_date DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await pool.query(query, params);

        // ── Get total count ──────────────────────────────────────
        let countQuery = 'SELECT COUNT(*) as total FROM expenses WHERE station_id = $1';
        const countParams = [stationId];
        let countIndex = 2;

        if (category) {
            countQuery += ` AND category = $${countIndex}`;
            countParams.push(category);
            countIndex++;
        }

        if (start_date) {
            countQuery += ` AND DATE(expense_date) >= $${countIndex}`;
            countParams.push(start_date);
            countIndex++;
        }

        if (end_date) {
            countQuery += ` AND DATE(expense_date) <= $${countIndex}`;
            countParams.push(end_date);
            countIndex++;
        }

        const countResult = await pool.query(countQuery, countParams);

        res.json({
            success: true,
            data: result.rows.map(row => ({
                id: row.id,
                category: row.category,
                amount: parseFloat(row.amount || 0),
                description: row.description,
                expenseDate: row.expense_date,
                vendorName: row.vendor_name,
                paymentMethod: row.payment_method,
                referenceNumber: row.reference_number,
                createdBy: row.created_by,
                isRecurring: row.is_recurring,
                recurringIntervalDays: row.recurring_interval_days,
                notes: row.notes,
                createdAt: row.created_at
            })),
            total: parseInt(countResult.rows[0].total || 0)
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
        const userId = req.user.userId;
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

        // ── Create expense ──────────────────────────────────────
        const result = await pool.query(
            `INSERT INTO expenses 
             (station_id, category, amount, description, expense_date, vendor_name, 
              payment_method, reference_number, created_by, is_recurring, 
              recurring_interval_days, notes)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
             RETURNING *`,
            [stationId, category, parseFloat(amount), description, 
             expense_date || new Date().toISOString().split('T')[0],
             vendor_name || null, payment_method || null, reference_number || null,
             userId, is_recurring || false, recurring_interval_days || null, notes || null]
        );

        // ── Log the action ──────────────────────────────────────
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'EXPENSE_CREATED', $2, $3)`,
            [userId, `Expense created: ${category} - KES ${amount}`, stationId]
        );

        res.status(201).json({
            success: true,
            message: 'Expense recorded successfully',
            data: result.rows[0]
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
        const userId = req.user.userId;
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

        // ── Check expense exists ───────────────────────────────
        const checkResult = await pool.query(
            `SELECT id FROM expenses WHERE id = $1 AND station_id = $2`,
            [id, stationId]
        );

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Expense not found'
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
        const userId = req.user.userId;
        const { id } = req.params;

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

        // ── Check and delete ────────────────────────────────────
        const result = await pool.query(
            `DELETE FROM expenses WHERE id = $1 AND station_id = $2 RETURNING id`,
            [id, stationId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Expense not found'
            });
        }

        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details, station_id)
             VALUES ($1, 'EXPENSE_DELETED', $2, $3)`,
            [userId, `Expense ${id} deleted`, stationId]
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
        const userId = req.user.userId;
        const { start_date, end_date } = req.query;

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

        let query = `
            SELECT 
                category,
                COALESCE(SUM(amount), 0) as total
            FROM expenses
            WHERE station_id = $1
        `;

        const params = [stationId];
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

        query += ` GROUP BY category ORDER BY category`;

        const result = await pool.query(query, params);

        res.json({
            success: true,
            data: result.rows.map(row => ({
                category: row.category,
                total: parseFloat(row.total || 0)
            }))
        });

    } catch (err) {
        console.error('Get expense categories error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load expense categories'
        });
    }
};

module.exports = {
    getExpenses,
    createExpense,
    updateExpense,
    deleteExpense,
    getExpenseCategories
};