// src/controllers/customerController.js
const pool = require('../config/database');

// ──────────────────────────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────────────────────────

/**
 * Tier thresholds — mirrors Customer.updateTier() on the Flutter side
 * exactly, so the server-computed tier always matches what the client
 * would compute from the same total_spent value.
 */
function computeTier(totalSpent) {
    const spent = Number(totalSpent) || 0;
    if (spent >= 100000) return 'platinum';
    if (spent >= 50000) return 'gold';
    if (spent >= 20000) return 'silver';
    return 'bronze';
}

/**
 * Maps a raw `customers` row to the exact snake_case shape
 * Customer.fromBackendJson expects on the Flutter side.
 */
function mapCustomerRow(row) {
    return {
        id: row.id,
        name: row.name,
        phone: row.phone,
        email: row.email,
        created_at: row.created_at,
        total_spent: row.total_spent,
        total_liters: row.total_liters,
        points_balance: row.points_balance,
        points_earned: row.points_earned,
        points_redeemed: row.points_redeemed,
        last_purchase_date: row.last_purchase_date,
        total_transactions: row.total_transactions,
        vehicle_number: row.vehicle_number,
        preferred_fuel: row.preferred_fuel,
        tier: row.tier,
        notes: row.notes,
    };
}

/**
 * Updates a customer's tier and points based on a new transaction.
 * Called from transactionController when a sale is linked to a customer.
 *
 * Points rule: 1 point per liter dispensed (NOT per KES spent — fixed
 * from an earlier version of this file that used 1 point per 100 KES).
 *
 * IMPORTANT: explicitly sets type='earned' on the ledger row. The
 * points_redemptions table's `type` column defaults to 'redeemed',
 * and earlier this function didn't set it at all — which silently
 * mislabeled every earned-points event as a redemption. That corrupted
 * both the points_redeemed-vs-earned bookkeeping and would have shown
 * fake redemptions in the customer's transaction history.
 */
async function updateCustomerFromTransaction(customerId, amount, litersDispensed, userId) {
    try {
        const customerResult = await pool.query(
            `SELECT total_spent, total_liters, points_balance, points_earned, tier 
             FROM customers WHERE id = $1`,
            [customerId]
        );

        if (customerResult.rows.length === 0) {
            return null;
        }

        const customer = customerResult.rows[0];
        const newTotalSpent = parseFloat(customer.total_spent || 0) + parseFloat(amount || 0);
        const newTotalLiters = parseFloat(customer.total_liters || 0) + parseFloat(litersDispensed || 0);

        // ── Points: 1 point per liter dispensed ──────────────
        const pointsEarned = Math.floor(parseFloat(litersDispensed || 0));
        const newPointsBalance = parseInt(customer.points_balance || 0) + pointsEarned;
        const newPointsEarned = parseInt(customer.points_earned || 0) + pointsEarned;

        const newTier = computeTier(newTotalSpent);

        await pool.query(
            `UPDATE customers 
             SET total_spent = $1,
                 total_liters = $2,
                 points_balance = $3,
                 points_earned = $4,
                 tier = $5,
                 total_transactions = total_transactions + 1,
                 last_purchase_date = NOW()
             WHERE id = $6`,
            [newTotalSpent, newTotalLiters, newPointsBalance, newPointsEarned, newTier, customerId]
        );

        // Log points earned — type='earned' is explicit and required;
        // do not rely on the column default here.
        if (pointsEarned > 0) {
            await pool.query(
                `INSERT INTO points_redemptions (customer_id, points, redeemed_by, notes, type)
                 VALUES ($1, $2, $3, $4, 'earned')`,
                [customerId, pointsEarned, userId, `Earned ${pointsEarned} pts for ${litersDispensed}L purchase (KES ${amount})`]
            );
        }

        return {
            pointsEarned,
            newPointsBalance,
            newTier,
            tierChanged: newTier !== customer.tier
        };

    } catch (err) {
        console.error('updateCustomerFromTransaction error:', err);
        throw err;
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// GET CUSTOMERS (list, with optional search)
// ──────────────────────────────────────────────────────────────────────────────

const getCustomers = async (req, res) => {
    try {
        const { search, tier } = req.query;

        let query = 'SELECT * FROM customers WHERE 1=1';
        const params = [];
        let paramCount = 1;

        if (search) {
            query += ` AND (name ILIKE $${paramCount} OR phone ILIKE $${paramCount} OR vehicle_number ILIKE $${paramCount})`;
            params.push(`%${search}%`);
            paramCount++;
        }

        if (tier) {
            const validTiers = ['bronze', 'silver', 'gold', 'platinum'];
            if (!validTiers.includes(tier)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid tier. Must be one of: ${validTiers.join(', ')}`
                });
            }
            query += ` AND tier = $${paramCount}`;
            params.push(tier);
            paramCount++;
        }

        query += ' ORDER BY total_spent DESC';

        const result = await pool.query(query, params);

        res.json({
            success: true,
            data: result.rows.map(mapCustomerRow),
            count: result.rows.length
        });

    } catch (err) {
        console.error('Get customers error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve customers' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// SEARCH CUSTOMER BY PHONE (point-of-sale lookup)
// ──────────────────────────────────────────────────────────────────────────────

const searchCustomerByPhone = async (req, res) => {
    try {
        const { phone } = req.query;

        if (!phone) {
            return res.status(400).json({ success: false, message: 'Phone number is required' });
        }

        const result = await pool.query(
            'SELECT * FROM customers WHERE phone = $1',
            [phone.trim()]
        );

        if (result.rows.length === 0) {
            return res.json({ success: true, found: false, data: null });
        }

        res.json({ success: true, found: true, data: mapCustomerRow(result.rows[0]) });

    } catch (err) {
        console.error('Search customer by phone error:', err);
        res.status(500).json({ success: false, message: 'Failed to search customer' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET CUSTOMER BY ID
// ──────────────────────────────────────────────────────────────────────────────

const getCustomerById = async (req, res) => {
    const { id } = req.params;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid customer ID' });
        }

        const result = await pool.query('SELECT * FROM customers WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Customer not found' });
        }

        res.json({ success: true, data: mapCustomerRow(result.rows[0]) });

    } catch (err) {
        console.error('Get customer by ID error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve customer' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// GET CUSTOMER TRANSACTION HISTORY (fuel purchases + redemptions, merged)
// ──────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/customers/:id/transactions
 * Response shape matches CustomerTransaction.fromJson on the Flutter
 * side EXACTLY (camelCase) — this is a different convention from the
 * snake_case Customer model above; getting this wrong reproduces the
 * same silent-parse-failure bug we hit with employees.
 *
 * IMPORTANT: the redemptions query filters `type = 'redeemed'` only.
 * Without this filter, 'earned' ledger rows (written by
 * updateCustomerFromTransaction above) would leak into this list as
 * fake redemptions — the real purchase already appears via the
 * `transactions` join, so showing the matching 'earned' ledger row
 * too would be a confusing duplicate, not new information.
 */
const getCustomerTransactions = async (req, res) => {
    const { id } = req.params;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid customer ID' });
        }

        const purchases = await pool.query(
            `SELECT 
                t.id,
                t.customer_id,
                t.amount,
                t.liters_dispensed AS liters,
                t.created_at AS date,
                t.pump_id,
                u.full_name AS attendant_name,
                t.liters_dispensed AS points_earned
             FROM transactions t
             LEFT JOIN users u ON t.attendant_id = u.id
             WHERE t.customer_id = $1 AND t.status = 'completed'`,
            [id]
        );

        const redemptions = await pool.query(
            `SELECT 
                id,
                customer_id,
                points,
                created_at AS date,
                notes
             FROM points_redemptions
             WHERE customer_id = $1 AND type = 'redeemed'`,
            [id]
        );

        const purchaseItems = purchases.rows.map(row => ({
            id: `txn-${row.id}`,
            customerId: row.customer_id.toString(),
            amount: Number(row.amount) || 0,
            liters: Number(row.liters) || 0,
            date: row.date,
            pumpId: row.pump_id?.toString() ?? '',
            attendantName: row.attendant_name || 'Unknown',
            pointsEarned: Math.floor(Number(row.points_earned) || 0),
            type: 'fuelPurchase',
        }));

        const redemptionItems = redemptions.rows.map(row => ({
            id: `redeem-${row.id}`,
            customerId: row.customer_id.toString(),
            amount: 0,
            liters: 0,
            date: row.date,
            pumpId: '',
            attendantName: row.notes || 'Points redeemed',
            pointsEarned: row.points,
            type: 'pointsRedemption',
        }));

        const combined = [...purchaseItems, ...redemptionItems].sort(
            (a, b) => new Date(b.date) - new Date(a.date)
        );

        res.json({ success: true, data: combined, count: combined.length });

    } catch (err) {
        console.error('Get customer transactions error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve customer transactions' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// CREATE CUSTOMER
// ──────────────────────────────────────────────────────────────────────────────

const createCustomer = async (req, res) => {
    const { name, phone, email, vehicle_number, preferred_fuel, notes } = req.body;

    try {
        if (!name || !phone) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: name, phone'
            });
        }

        const existing = await pool.query('SELECT id FROM customers WHERE phone = $1', [phone.trim()]);
        if (existing.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'A customer with this phone number is already registered.'
            });
        }

        const result = await pool.query(
            `INSERT INTO customers (name, phone, email, vehicle_number, preferred_fuel, notes, tier)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             RETURNING *`,
            [name.trim(), phone.trim(), email || null, vehicle_number || null,
             preferred_fuel || null, notes || null, 'bronze']
        );

        res.status(201).json({
            success: true,
            message: 'Customer registered successfully',
            data: mapCustomerRow(result.rows[0])
        });

    } catch (err) {
        console.error('Create customer error:', err);
        res.status(500).json({ success: false, message: 'Failed to create customer' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// UPDATE CUSTOMER (details only — not points/tier, use dedicated endpoints)
// ──────────────────────────────────────────────────────────────────────────────

const updateCustomer = async (req, res) => {
    const { id } = req.params;
    const { name, phone, email, vehicle_number, preferred_fuel, notes } = req.body;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid customer ID' });
        }

        const updates = [];
        const values = [];
        let paramCount = 1;

        if (name !== undefined) { updates.push(`name = $${paramCount}`); values.push(name); paramCount++; }
        if (phone !== undefined) { updates.push(`phone = $${paramCount}`); values.push(phone); paramCount++; }
        if (email !== undefined) { updates.push(`email = $${paramCount}`); values.push(email || null); paramCount++; }
        if (vehicle_number !== undefined) { updates.push(`vehicle_number = $${paramCount}`); values.push(vehicle_number || null); paramCount++; }
        if (preferred_fuel !== undefined) { updates.push(`preferred_fuel = $${paramCount}`); values.push(preferred_fuel || null); paramCount++; }
        if (notes !== undefined) { updates.push(`notes = $${paramCount}`); values.push(notes || null); paramCount++; }

        if (updates.length === 0) {
            return res.status(400).json({ success: false, message: 'No fields to update' });
        }

        values.push(id);
        const query = `UPDATE customers SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;
        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Customer not found' });
        }

        res.json({
            success: true,
            message: 'Customer updated successfully',
            data: mapCustomerRow(result.rows[0])
        });

    } catch (err) {
        console.error('Update customer error:', err);
        res.status(500).json({ success: false, message: 'Failed to update customer' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// ADJUST POINTS (manual add/subtract, e.g. promotional bonus or correction)
// ──────────────────────────────────────────────────────────────────────────────

/**
 * PUT /api/customers/:id/points
 * A positive delta logs as type='adjustment' (not 'earned' — this is a
 * manual override, not a real per-liter earning event, so it shouldn't
 * be counted as if the customer bought fuel). A negative delta also
 * logs as type='adjustment', not 'redeemed' — redemptions go through
 * the dedicated /redeem endpoint below, which enforces a sufficient-
 * balance check that this endpoint intentionally does not.
 */
const adjustCustomerPoints = async (req, res) => {
    const { id } = req.params;
    const { points, notes } = req.body;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid customer ID' });
        }

        const pointsDelta = parseInt(points, 10);
        if (isNaN(pointsDelta) || pointsDelta === 0) {
            return res.status(400).json({ success: false, message: 'points must be a non-zero integer' });
        }

        const customerResult = await pool.query('SELECT points_balance FROM customers WHERE id = $1', [id]);
        if (customerResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Customer not found' });
        }

        const currentBalance = customerResult.rows[0].points_balance;
        const newBalance = currentBalance + pointsDelta;

        if (newBalance < 0) {
            return res.status(400).json({
                success: false,
                message: 'Adjustment would make points_balance negative'
            });
        }

        const query = pointsDelta > 0
            ? `UPDATE customers 
               SET points_balance = points_balance + $1, points_earned = points_earned + $1
               WHERE id = $2 RETURNING *`
            : `UPDATE customers 
               SET points_balance = points_balance + $1
               WHERE id = $2 RETURNING *`;

        const result = await pool.query(query, [pointsDelta, id]);

        await pool.query(
            `INSERT INTO points_redemptions (customer_id, points, redeemed_by, notes, type)
             VALUES ($1, $2, $3, $4, 'adjustment')`,
            [id, Math.abs(pointsDelta), req.user.userId,
             notes || `Manual points adjustment: ${pointsDelta > 0 ? '+' : ''}${pointsDelta}`]
        );

        res.json({
            success: true,
            message: 'Points adjusted successfully',
            data: mapCustomerRow(result.rows[0])
        });

    } catch (err) {
        console.error('Adjust customer points error:', err);
        res.status(500).json({ success: false, message: 'Failed to adjust points' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// REDEEM POINTS
// ──────────────────────────────────────────────────────────────────────────────

const redeemCustomerPoints = async (req, res) => {
    const { id } = req.params;
    const { points, notes } = req.body;
    const userId = req.user.userId;

    try {
        if (isNaN(id)) {
            return res.status(400).json({ success: false, message: 'Invalid customer ID' });
        }

        const redeemAmount = parseInt(points, 10);
        if (isNaN(redeemAmount) || redeemAmount <= 0) {
            return res.status(400).json({ success: false, message: 'points must be a positive integer' });
        }

        const customerResult = await pool.query('SELECT points_balance FROM customers WHERE id = $1', [id]);
        if (customerResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Customer not found' });
        }

        const currentBalance = customerResult.rows[0].points_balance;
        if (redeemAmount > currentBalance) {
            return res.status(400).json({
                success: false,
                message: `Insufficient points balance. Available: ${currentBalance}, requested: ${redeemAmount}`
            });
        }

        await pool.query('BEGIN');

        await pool.query(
            `UPDATE customers 
             SET points_balance = points_balance - $1, points_redeemed = points_redeemed + $1
             WHERE id = $2`,
            [redeemAmount, id]
        );

        const ledgerResult = await pool.query(
            `INSERT INTO points_redemptions (customer_id, points, redeemed_by, notes, type)
             VALUES ($1, $2, $3, $4, 'redeemed')
             RETURNING *`,
            [id, redeemAmount, userId, notes || null]
        );

        await pool.query('COMMIT');

        res.json({
            success: true,
            message: `Redeemed ${redeemAmount} points successfully`,
            data: ledgerResult.rows[0]
        });

    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Redeem customer points error:', err);
        res.status(500).json({ success: false, message: 'Failed to redeem points' });
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ──────────────────────────────────────────────────────────────────────────────

module.exports = {
    getCustomers,
    searchCustomerByPhone,
    getCustomerById,
    getCustomerTransactions,
    createCustomer,
    updateCustomer,
    adjustCustomerPoints,
    redeemCustomerPoints,
    computeTier,
    updateCustomerFromTransaction, // For transactionController to use
};