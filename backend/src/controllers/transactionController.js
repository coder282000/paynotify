// src/controllers/transactionController.js
const pool = require('../config/database');
const { updateCustomerFromTransaction } = require('./customerController');

/**
 * GET /api/transactions
 * Retrieve transactions (attendants see own, managers/supervisors see all)
 */
const getTransactions = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { limit = 50, offset = 0, status, pump_id } = req.query;

        let query = `
            SELECT 
                t.id,
                t.amount,
                t.phone,
                t.customer_name,
                t.customer_id,
                t.payment_type,
                t.status,
                t.pump_id,
                t.attendant_id,
                t.liters_dispensed,
                t.mpesa_reference,
                t.note,
                t.created_at,
                p.pump_number,
                u.username as attendant_name
            FROM transactions t
            LEFT JOIN pumps p ON t.pump_id = p.id
            LEFT JOIN users u ON t.attendant_id = u.id
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        // Role-based filtering
        if (userRole === 'attendant') {
            query += ` AND t.attendant_id = $${paramCount}`;
            params.push(userId);
            paramCount++;
        }

        // Optional status filter
        if (status) {
            query += ` AND t.status = $${paramCount}`;
            params.push(status);
            paramCount++;
        }

        // Optional pump filter
        if (pump_id) {
            query += ` AND t.pump_id = $${paramCount}`;
            params.push(pump_id);
            paramCount++;
        }

        // Order and pagination
        query += ` ORDER BY t.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        params.push(limit);
        params.push(offset);

        const result = await pool.query(query, params);

        // Format response
        const transactions = result.rows.map(t => ({
            id: t.id,
            amount: parseFloat(t.amount),
            phone: t.phone,
            customerName: t.customer_name,
            customerId: t.customer_id,
            paymentType: t.payment_type,
            status: t.status,
            pumpId: t.pump_id,
            pumpNumber: t.pump_number,
            attendantId: t.attendant_id,
            attendantName: t.attendant_name,
            litersDispensed: t.liters_dispensed ? parseFloat(t.liters_dispensed) : null,
            mpesaReference: t.mpesa_reference,
            note: t.note,
            createdAt: t.created_at
        }));

        res.json({
            success: true,
            data: transactions,
            count: transactions.length
        });

    } catch (err) {
        console.error('Get transactions error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve transactions'
        });
    }
};

/**
 * Looks up a customer by phone (if provided) and, if found, links the
 * transaction to them and awards loyalty points (1 per liter).
 *
 * Per business rule: an unmatched phone number is NOT an error and does
 * NOT auto-create a customer — the sale just proceeds unlinked and
 * earns no points. Returns { customerId, loyalty } where `loyalty` is
 * null if no customer was linked, or the result of
 * updateCustomerFromTransaction() if one was.
 */
async function linkCustomerToSale(customerPhone, amount, litersDispensed, attendantId) {
    if (!customerPhone) {
        return { customerId: null, loyalty: null };
    }

    const customerResult = await pool.query(
        'SELECT id FROM customers WHERE phone = $1',
        [customerPhone.trim()]
    );

    if (customerResult.rows.length === 0) {
        // Not a registered loyalty member — proceed unlinked, no points.
        return { customerId: null, loyalty: null };
    }

    const customerId = customerResult.rows[0].id;
    const loyalty = await updateCustomerFromTransaction(customerId, amount, litersDispensed, attendantId);

    return { customerId, loyalty };
}

/**
 * POST /api/transactions/cash
 * Record a cash sale transaction
 */
const recordCashSale = async (req, res) => {
    const { pump_id, amount, customer_name, customer_phone, liters_dispensed, note } = req.body;
    const attendantId = req.user.userId;

    try {
        // Validate inputs
        if (!pump_id || !amount) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: pump_id, amount'
            });
        }

        // Check pump exists
        const pumpCheck = await pool.query(
            'SELECT id, pump_number FROM pumps WHERE id = $1',
            [pump_id]
        );

        if (pumpCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pump not found'
            });
        }

        // Look up customer by phone (optional — see linkCustomerToSale)
        const { customerId, loyalty } = await linkCustomerToSale(
            customer_phone, amount, liters_dispensed, attendantId
        );

        // Create transaction
        const result = await pool.query(
            `INSERT INTO transactions 
             (amount, payment_type, status, pump_id, attendant_id, customer_name, phone, customer_id, liters_dispensed, note)
             VALUES ($1, 'cash', 'completed', $2, $3, $4, $5, $6, $7, $8)
             RETURNING id, amount, payment_type, status, pump_id, attendant_id, customer_id, created_at`,
            [
                parseFloat(amount), pump_id, attendantId, customer_name || null,
                customer_phone || null, customerId, liters_dispensed || null, note || null
            ]
        );

        const transaction = result.rows[0];

        // Log the transaction
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details)
             VALUES ($1, 'CASH_SALE', $2)`,
            [attendantId, `Cash sale: KES ${amount} at pump ${pumpCheck.rows[0].pump_number}`]
        );

        res.status(201).json({
            success: true,
            message: 'Cash sale recorded successfully',
            data: {
                id: transaction.id,
                amount: parseFloat(transaction.amount),
                paymentType: transaction.payment_type,
                status: transaction.status,
                pumpId: transaction.pump_id,
                attendantId: transaction.attendant_id,
                customerId: transaction.customer_id,
                createdAt: transaction.created_at,
                loyalty: loyalty ? {
                    pointsEarned: loyalty.pointsEarned,
                    newPointsBalance: loyalty.newPointsBalance,
                    newTier: loyalty.newTier,
                    tierChanged: loyalty.tierChanged
                } : null
            }
        });

    } catch (err) {
        console.error('Record cash sale error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to record cash sale'
        });
    }
};

/**
 * POST /api/transactions/card
 * Record a card sale transaction
 */
const recordCardSale = async (req, res) => {
    const { pump_id, amount, customer_name, customer_phone, liters_dispensed, note } = req.body;
    const attendantId = req.user.userId;

    try {
        // Validate inputs
        if (!pump_id || !amount) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: pump_id, amount'
            });
        }

        // Check pump exists
        const pumpCheck = await pool.query(
            'SELECT id, pump_number FROM pumps WHERE id = $1',
            [pump_id]
        );

        if (pumpCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pump not found'
            });
        }

        // Look up customer by phone (optional — see linkCustomerToSale)
        const { customerId, loyalty } = await linkCustomerToSale(
            customer_phone, amount, liters_dispensed, attendantId
        );

        // Create transaction
        const result = await pool.query(
            `INSERT INTO transactions 
             (amount, payment_type, status, pump_id, attendant_id, customer_name, phone, customer_id, liters_dispensed, note)
             VALUES ($1, 'card', 'completed', $2, $3, $4, $5, $6, $7, $8)
             RETURNING id, amount, payment_type, status, pump_id, attendant_id, customer_id, created_at`,
            [
                parseFloat(amount), pump_id, attendantId, customer_name || null,
                customer_phone || null, customerId, liters_dispensed || null, note || null
            ]
        );

        const transaction = result.rows[0];

        // Log the transaction
        await pool.query(
            `INSERT INTO audit_logs (user_id, event_type, details)
             VALUES ($1, 'CARD_SALE', $2)`,
            [attendantId, `Card sale: KES ${amount} at pump ${pumpCheck.rows[0].pump_number}`]
        );

        res.status(201).json({
            success: true,
            message: 'Card sale recorded successfully',
            data: {
                id: transaction.id,
                amount: parseFloat(transaction.amount),
                paymentType: transaction.payment_type,
                status: transaction.status,
                pumpId: transaction.pump_id,
                attendantId: transaction.attendant_id,
                customerId: transaction.customer_id,
                createdAt: transaction.created_at,
                loyalty: loyalty ? {
                    pointsEarned: loyalty.pointsEarned,
                    newPointsBalance: loyalty.newPointsBalance,
                    newTier: loyalty.newTier,
                    tierChanged: loyalty.tierChanged
                } : null
            }
        });

    } catch (err) {
        console.error('Record card sale error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to record card sale'
        });
    }
};

/**
 * POST /api/transactions/mpesa
 * Initiate M-Pesa STK Push (Phase 6 - Placeholder for now)
 */
const initiateMpesa = async (req, res) => {
    const { pump_id, amount, phone_number } = req.body;
    const attendantId = req.user.userId;

    try {
        // Validate inputs
        if (!pump_id || !amount || !phone_number) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: pump_id, amount, phone_number'
            });
        }

        // Placeholder response - actual M-Pesa integration comes in Phase 6
        res.json({
            success: true,
            message: 'M-Pesa integration coming soon',
            data: {
                status: 'pending',
                pumpId: pump_id,
                amount: parseFloat(amount),
                phoneNumber: phone_number,
                message: 'STK push will be sent to customer'
            }
        });

    } catch (err) {
        console.error('Initiate M-Pesa error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to initiate M-Pesa payment'
        });
    }
};

/**
 * GET /api/transactions/summary
 * Get transaction summary (Manager & Supervisor only)
 */
const getTransactionSummary = async (req, res) => {
    try {
        const { start_date, end_date } = req.query;

        // Build date filter if provided
        let dateFilter = '';
        const params = [];

        if (start_date && end_date) {
            dateFilter = `
                AND DATE(t.created_at) >= $1 
                AND DATE(t.created_at) <= $2
            `;
            params.push(start_date, end_date);
        }

        // Get summary statistics
        const result = await pool.query(`
            SELECT 
                COUNT(*) as total_transactions,
                SUM(CASE WHEN t.payment_type = 'cash' THEN t.amount ELSE 0 END) as cash_total,
                SUM(CASE WHEN t.payment_type = 'card' THEN t.amount ELSE 0 END) as card_total,
                SUM(CASE WHEN t.payment_type = 'mpesa' THEN t.amount ELSE 0 END) as mpesa_total,
                SUM(t.amount) as total_amount,
                AVG(t.amount) as average_amount,
                MAX(t.amount) as max_amount,
                COUNT(DISTINCT DATE(t.created_at)) as transaction_days
            FROM transactions t
            WHERE t.status = 'completed'
            ${dateFilter}
        `, params);

        const summary = result.rows[0];

        // Get transactions by pump
        const pumpResult = await pool.query(`
            SELECT 
                p.id,
                p.pump_number,
                COUNT(*) as pump_transactions,
                SUM(t.amount) as pump_total
            FROM transactions t
            LEFT JOIN pumps p ON t.pump_id = p.id
            WHERE t.status = 'completed'
            ${dateFilter}
            GROUP BY p.id, p.pump_number
            ORDER BY pump_total DESC
        `, params);

        // Get transactions by payment type
        const paymentResult = await pool.query(`
            SELECT 
                payment_type,
                COUNT(*) as type_count,
                SUM(amount) as type_total
            FROM transactions
            WHERE status = 'completed'
            ${dateFilter}
            GROUP BY payment_type
        `, params);

        res.json({
            success: true,
            data: {
                overview: {
                    totalTransactions: parseInt(summary.total_transactions),
                    totalAmount: parseFloat(summary.total_amount || 0),
                    averageAmount: parseFloat(summary.average_amount || 0),
                    maxAmount: parseFloat(summary.max_amount || 0),
                    transactionDays: parseInt(summary.transaction_days)
                },
                byPaymentType: {
                    cash: parseFloat(summary.cash_total || 0),
                    card: parseFloat(summary.card_total || 0),
                    mpesa: parseFloat(summary.mpesa_total || 0)
                },
                byPump: pumpResult.rows.map(p => ({
                    pumpId: p.id,
                    pumpNumber: p.pump_number,
                    transactionCount: parseInt(p.pump_transactions),
                    totalAmount: parseFloat(p.pump_total || 0)
                })),
                byPaymentTypeDetailed: paymentResult.rows.map(p => ({
                    paymentType: p.payment_type,
                    count: parseInt(p.type_count),
                    total: parseFloat(p.type_total || 0)
                }))
            }
        });

    } catch (err) {
        console.error('Get transaction summary error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve transaction summary'
        });
    }
};

module.exports = {
    getTransactions,
    recordCashSale,
    recordCardSale,
    initiateMpesa,
    getTransactionSummary
};