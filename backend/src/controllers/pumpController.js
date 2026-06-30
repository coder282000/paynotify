// src/controllers/pumpController.js
const pool = require('../config/database');

/**
 * GET /api/pumps
 * Get all pumps — optionally filtered by station_id query param
 * All roles can view pumps
 */
const getAllPumps = async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT
        p.id,
        p.pump_number,
        p.fuel_type,
        p.status,
        p.price_per_liter,
        p.current_reading,
        p.tank_capacity,
        p.current_fuel_level,
        p.low_fuel_threshold,
        p.is_active,
        p.station_id,
        p.current_attendant_id,
        u.username  AS current_attendant_name,
        s.station_name
      FROM pumps p
      LEFT JOIN users u ON p.current_attendant_id = u.id
      LEFT JOIN stations s ON p.station_id = s.id
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (station_id) {
      query += ` AND p.station_id = $${paramCount}`;
      params.push(station_id);
      paramCount++;
    }

    query += ` ORDER BY p.pump_number ASC`;

    const result = await pool.query(query, params);

    const pumps = result.rows.map(pump => ({
      id: pump.id,
      pumpNumber: pump.pump_number,
      fuelType: pump.fuel_type,
      status: pump.status,
      pricePerLiter: parseFloat(pump.price_per_liter),
      currentReading: parseFloat(pump.current_reading || 0),
      tankCapacity: parseFloat(pump.tank_capacity || 0),
      currentFuelLevel: parseFloat(pump.current_fuel_level || 0),
      lowFuelThreshold: parseFloat(pump.low_fuel_threshold || 15),
      isActive: pump.is_active,
      stationId: pump.station_id,
      stationName: pump.station_name,
      currentAttendantId: pump.current_attendant_id,
      currentAttendantName: pump.current_attendant_name,
    }));

    res.json({
      success: true,
      data: pumps,
      count: pumps.length,
    });

  } catch (err) {
    console.error('Get all pumps error:', err);
    res.status(500).json({ success: false, message: 'Failed to retrieve pumps' });
  }
};

/**
 * GET /api/pumps/:id
 * Get single pump with attendant info
 */
const getPumpById = async (req, res) => {
  const { id } = req.params;

  try {
    if (isNaN(id)) {
      return res.status(400).json({ success: false, message: 'Invalid pump ID' });
    }

    const result = await pool.query(
      `SELECT
          p.id, p.pump_number, p.fuel_type, p.status,
          p.price_per_liter, p.current_reading, p.tank_capacity,
          p.current_fuel_level, p.low_fuel_threshold,
          p.current_attendant_id, p.is_active, p.station_id,
          u.username AS attendant_username,
          u.full_name AS attendant_full_name,
          s.station_name
       FROM pumps p
       LEFT JOIN users u ON p.current_attendant_id = u.id
       LEFT JOIN stations s ON p.station_id = s.id
       WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pump not found' });
    }

    const pump = result.rows[0];

    res.json({
      success: true,
      data: {
        id: pump.id,
        pumpNumber: pump.pump_number,
        fuelType: pump.fuel_type,
        status: pump.status,
        pricePerLiter: parseFloat(pump.price_per_liter),
        currentReading: parseFloat(pump.current_reading || 0),
        tankCapacity: parseFloat(pump.tank_capacity || 0),
        currentFuelLevel: parseFloat(pump.current_fuel_level || 0),
        lowFuelThreshold: parseFloat(pump.low_fuel_threshold || 15),
        isActive: pump.is_active,
        stationId: pump.station_id,
        stationName: pump.station_name,
        currentAttendant: pump.current_attendant_id ? {
          id: pump.current_attendant_id,
          username: pump.attendant_username,
          fullName: pump.attendant_full_name,
        } : null,
      },
    });

  } catch (err) {
    console.error('Get pump by ID error:', err);
    res.status(500).json({ success: false, message: 'Failed to retrieve pump' });
  }
};

/**
 * POST /api/pumps
 * Create new pump — manager only
 * Required: pump_number, fuel_type, price_per_liter, station_id
 * Optional: tank_capacity (default 10000)
 */
const createPump = async (req, res) => {
  const { pump_number, fuel_type, price_per_liter, tank_capacity, station_id } = req.body;

  try {
    if (!pump_number || !fuel_type || !price_per_liter || !station_id) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: pump_number, fuel_type, price_per_liter, station_id',
      });
    }

    const validFuelTypes = ['petrol', 'diesel', 'kerosene', 'premium'];
    if (!validFuelTypes.includes(fuel_type.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: `Invalid fuel_type. Must be one of: ${validFuelTypes.join(', ')}`,
      });
    }

    // Verify station exists
    const stationCheck = await pool.query(
      'SELECT id FROM stations WHERE id = $1',
      [station_id]
    );
    if (stationCheck.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Station not found' });
    }

    // Check pump number unique within station
    const existing = await pool.query(
      'SELECT id FROM pumps WHERE pump_number = $1 AND station_id = $2',
      [pump_number, station_id]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: `Pump "${pump_number}" already exists at this station`,
      });
    }

    const result = await pool.query(
      `INSERT INTO pumps
         (pump_number, fuel_type, price_per_liter, tank_capacity, station_id, is_active, status)
       VALUES ($1, $2, $3, $4, $5, true, 'active')
       RETURNING id, pump_number, fuel_type, price_per_liter, status, station_id, is_active`,
      [pump_number, fuel_type.toLowerCase(), parseFloat(price_per_liter), tank_capacity || 10000, station_id]
    );

    const pump = result.rows[0];

    await pool.query(
      `INSERT INTO audit_logs (user_id, event_type, details)
       VALUES ($1, 'PUMP_CREATED', $2)`,
      [req.user.userId, `Pump ${pump_number} created at station ${station_id}`]
    );

    res.status(201).json({
      success: true,
      message: 'Pump created successfully',
      data: {
        id: pump.id,
        pumpNumber: pump.pump_number,
        fuelType: pump.fuel_type,
        pricePerLiter: parseFloat(pump.price_per_liter),
        status: pump.status,
        stationId: pump.station_id,
        isActive: pump.is_active,
      },
    });

  } catch (err) {
    console.error('Create pump error:', err);
    res.status(500).json({ success: false, message: 'Failed to create pump' });
  }
};

/**
 * PUT /api/pumps/:id/status
 * Update pump status — manager & supervisor
 */
const updatePumpStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const validStatuses = ['active', 'maintenance', 'inactive', 'occupied', 'emergency'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const pumpCheck = await pool.query('SELECT id, pump_number FROM pumps WHERE id = $1', [id]);
    if (pumpCheck.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pump not found' });
    }

    const result = await pool.query(
      `UPDATE pumps SET status = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, pump_number, status, updated_at`,
      [status, id]
    );

    const pump = result.rows[0];

    await pool.query(
      `INSERT INTO audit_logs (user_id, event_type, details) VALUES ($1, 'PUMP_STATUS_UPDATE', $2)`,
      [req.user.userId, `Pump ${pump.pump_number} status changed to ${status}`]
    );

    res.json({
      success: true,
      message: 'Pump status updated successfully',
      data: {
        id: pump.id,
        pumpNumber: pump.pump_number,
        status: pump.status,
        updatedAt: pump.updated_at,
      },
    });

  } catch (err) {
    console.error('Update pump status error:', err);
    res.status(500).json({ success: false, message: 'Failed to update pump status' });
  }
};

/**
 * PUT /api/pumps/:id/price
 * Update fuel price — manager only
 */
const updateFuelPrice = async (req, res) => {
  const { id } = req.params;
  const { price_per_liter } = req.body;

  try {
    if (!price_per_liter || isNaN(price_per_liter) || parseFloat(price_per_liter) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid price. Must be a positive number',
      });
    }

    const pumpCheck = await pool.query(
      'SELECT id, pump_number FROM pumps WHERE id = $1', [id]
    );
    if (pumpCheck.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pump not found' });
    }

    const result = await pool.query(
      `UPDATE pumps SET price_per_liter = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, pump_number, price_per_liter, updated_at`,
      [parseFloat(price_per_liter), id]
    );

    const pump = result.rows[0];

    await pool.query(
      `INSERT INTO audit_logs (user_id, event_type, details) VALUES ($1, 'PUMP_PRICE_UPDATE', $2)`,
      [req.user.userId, `Pump ${pump.pump_number} price updated to ${price_per_liter}`]
    );

    res.json({
      success: true,
      message: 'Pump price updated successfully',
      data: {
        id: pump.id,
        pumpNumber: pump.pump_number,
        pricePerLiter: parseFloat(pump.price_per_liter),
        updatedAt: pump.updated_at,
      },
    });

  } catch (err) {
    console.error('Update pump price error:', err);
    res.status(500).json({ success: false, message: 'Failed to update pump price' });
  }
};

module.exports = {
  getAllPumps,
  getPumpById,
  createPump,
  updatePumpStatus,
  updateFuelPrice,
};