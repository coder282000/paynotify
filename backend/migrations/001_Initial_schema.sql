-- ============================================================
-- PayNotify Database Migration - v1
-- Run this in pgAdmin Query Tool against paynotify_db
-- ============================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    role        VARCHAR(20) NOT NULL CHECK (role IN ('attendant', 'supervisor', 'manager')),
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login  TIMESTAMP
);

-- Pumps table
CREATE TABLE IF NOT EXISTS pumps (
    id                  SERIAL PRIMARY KEY,
    pump_number         VARCHAR(20) UNIQUE NOT NULL,
    fuel_type           VARCHAR(20) NOT NULL CHECK (fuel_type IN ('petrol', 'diesel', 'kerosene', 'premium')),
    status              VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive', 'occupied', 'emergency')),
    price_per_liter     NUMERIC(10,2) NOT NULL,
    current_meter       NUMERIC(12,2) DEFAULT 0,
    previous_meter      NUMERIC(12,2) DEFAULT 0,
    last_reading_date   TIMESTAMP,
    tank_capacity       NUMERIC(10,2) DEFAULT 10000,
    current_fuel_level  NUMERIC(10,2) DEFAULT 0,
    low_fuel_threshold  NUMERIC(5,2) DEFAULT 15.00,
    current_attendant_id INTEGER REFERENCES users(id),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id              SERIAL PRIMARY KEY,
    amount          NUMERIC(12,2) NOT NULL,
    phone           VARCHAR(20),
    customer_name   VARCHAR(100),
    payment_type    VARCHAR(20) NOT NULL CHECK (payment_type IN ('mpesa', 'cash', 'card')),
    status          VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    pump_id         INTEGER REFERENCES pumps(id),
    attendant_id    INTEGER REFERENCES users(id),
    liters_dispensed NUMERIC(10,3),
    mpesa_reference VARCHAR(50),
    note            TEXT,
    processed_by    INTEGER REFERENCES users(id),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Shift reports table
CREATE TABLE IF NOT EXISTS shift_reports (
    id                  SERIAL PRIMARY KEY,
    attendant_id        INTEGER REFERENCES users(id) NOT NULL,
    pump_id             INTEGER REFERENCES pumps(id) NOT NULL,
    shift_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    shift_start         TIMESTAMP NOT NULL,
    shift_end           TIMESTAMP,
    opening_meter       NUMERIC(12,2),
    closing_meter       NUMERIC(12,2),
    fuel_dispensed      NUMERIC(10,3),
    expected_cash       NUMERIC(12,2) DEFAULT 0,
    actual_cash         NUMERIC(12,2) DEFAULT 0,
    mpesa_total         NUMERIC(12,2) DEFAULT 0,
    cash_total          NUMERIC(12,2) DEFAULT 0,
    card_total          NUMERIC(12,2) DEFAULT 0,
    variance            NUMERIC(12,2) DEFAULT 0,
    status              VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'underReview')),
    approved_by         INTEGER REFERENCES users(id),
    approved_at         TIMESTAMP,
    remarks             TEXT,
    rejection_reason    TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Supervisor interventions table
CREATE TABLE IF NOT EXISTS supervisor_interventions (
    id              SERIAL PRIMARY KEY,
    supervisor_id   INTEGER REFERENCES users(id) NOT NULL,
    pump_id         INTEGER REFERENCES pumps(id),
    type            VARCHAR(30) NOT NULL CHECK (type IN ('sale', 'override', 'emergencyStop', 'refill', 'reading', 'shiftApproval')),
    amount          NUMERIC(12,2),
    customer_phone  VARCHAR(20),
    customer_name   VARCHAR(100),
    reason          TEXT NOT NULL,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Emergency events table
CREATE TABLE IF NOT EXISTS emergency_events (
    id                  SERIAL PRIMARY KEY,
    pump_id             INTEGER REFERENCES pumps(id) NOT NULL,
    supervisor_id       INTEGER REFERENCES users(id) NOT NULL,
    type                VARCHAR(30) NOT NULL CHECK (type IN ('fuelLeak', 'fire', 'pumpMalfunction', 'powerFailure', 'security', 'other')),
    reason              TEXT NOT NULL,
    is_resolved         BOOLEAN DEFAULT FALSE,
    resolved_at         TIMESTAMP,
    resolved_by         INTEGER REFERENCES users(id),
    resolution_notes    TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fuel tanks table
CREATE TABLE IF NOT EXISTS fuel_tanks (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL,
    fuel_type       VARCHAR(20) NOT NULL CHECK (fuel_type IN ('petrol', 'diesel', 'kerosene', 'premium')),
    capacity        NUMERIC(10,2) NOT NULL,
    current_level   NUMERIC(10,2) DEFAULT 0,
    min_threshold   NUMERIC(5,2) DEFAULT 15.00,
    supplier        VARCHAR(100),
    last_delivery_date   TIMESTAMP,
    last_delivery_amount NUMERIC(10,2),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fuel deliveries table
CREATE TABLE IF NOT EXISTS fuel_deliveries (
    id              SERIAL PRIMARY KEY,
    tank_id         INTEGER REFERENCES fuel_tanks(id) NOT NULL,
    amount_liters   NUMERIC(10,2) NOT NULL,
    cost_per_liter  NUMERIC(10,2) NOT NULL,
    total_cost      NUMERIC(12,2) NOT NULL,
    supplier        VARCHAR(100),
    invoice_number  VARCHAR(50),
    recorded_by     INTEGER REFERENCES users(id),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employees table (extended profile for staff)
CREATE TABLE IF NOT EXISTS employees (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER REFERENCES users(id) UNIQUE NOT NULL,
    employee_role   VARCHAR(30) DEFAULT 'attendant' CHECK (employee_role IN ('attendant', 'seniorAttendant', 'supervisor')),
    status          VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending', 'suspended')),
    assigned_pump_id INTEGER REFERENCES pumps(id),
    join_date       DATE DEFAULT CURRENT_DATE,
    last_active     TIMESTAMP,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    phone           VARCHAR(20) UNIQUE NOT NULL,
    email           VARCHAR(100),
    join_date       DATE DEFAULT CURRENT_DATE,
    total_spent     NUMERIC(12,2) DEFAULT 0,
    total_liters    NUMERIC(10,3) DEFAULT 0,
    points_balance  INTEGER DEFAULT 0,
    points_earned   INTEGER DEFAULT 0,
    points_redeemed INTEGER DEFAULT 0,
    last_purchase_date TIMESTAMP,
    total_transactions INTEGER DEFAULT 0,
    vehicle_number  VARCHAR(20),
    preferred_fuel  VARCHAR(20),
    tier            VARCHAR(20) DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id              SERIAL PRIMARY KEY,
    category        VARCHAR(30) NOT NULL CHECK (category IN ('fuelPurchase','salary','maintenance','utilities','rent','supplies','marketing','insurance','other')),
    amount          NUMERIC(12,2) NOT NULL,
    description     TEXT NOT NULL,
    expense_date    DATE DEFAULT CURRENT_DATE,
    vendor_name     VARCHAR(100),
    payment_method  VARCHAR(30),
    reference_number VARCHAR(50),
    created_by      INTEGER REFERENCES users(id),
    is_recurring    BOOLEAN DEFAULT FALSE,
    recurring_interval_days INTEGER,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications / announcements table
CREATE TABLE IF NOT EXISTS notifications (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    message         TEXT NOT NULL,
    sent_by         INTEGER REFERENCES users(id),
    target_roles    TEXT[] DEFAULT '{"attendant"}',
    is_read_by      INTEGER[] DEFAULT '{}',
    priority        VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs table (security events)
CREATE TABLE IF NOT EXISTS audit_logs (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id),
    event_type  VARCHAR(50) NOT NULL,
    ip_address  VARCHAR(45),
    details     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Meter readings table
CREATE TABLE IF NOT EXISTS meter_readings (
    id              SERIAL PRIMARY KEY,
    pump_id         INTEGER REFERENCES pumps(id) NOT NULL,
    reading_value   NUMERIC(12,2) NOT NULL,
    reading_type    VARCHAR(20) CHECK (reading_type IN ('opening', 'closing', 'interim', 'spot')),
    recorded_by     INTEGER REFERENCES users(id),
    previous_reading NUMERIC(12,2),
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_transactions_pump_id ON transactions(pump_id);
CREATE INDEX IF NOT EXISTS idx_transactions_attendant_id ON transactions(attendant_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_shift_reports_attendant_id ON shift_reports(attendant_id);
CREATE INDEX IF NOT EXISTS idx_shift_reports_status ON shift_reports(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- ============================================================
-- Seed data: 6 pumps
-- ============================================================
INSERT INTO pumps (pump_number, fuel_type, price_per_liter, tank_capacity, current_fuel_level) VALUES
    ('Pump 1', 'petrol',  176.50, 10000, 7500),
    ('Pump 2', 'petrol',  176.50, 10000, 6200),
    ('Pump 3', 'diesel',  162.00, 10000, 8100),
    ('Pump 4', 'diesel',  162.00, 10000, 4500),
    ('Pump 5', 'premium', 195.00, 5000,  3200),
    ('Pump 6', 'kerosene',120.00, 5000,  2800)
ON CONFLICT (pump_number) DO NOTHING;

-- ============================================================
-- Seed data: Fuel tanks linked to pumps
-- ============================================================
INSERT INTO fuel_tanks (name, fuel_type, capacity, current_level) VALUES
    ('Petrol Tank A',   'petrol',  20000, 13700),
    ('Diesel Tank A',   'diesel',  20000, 12600),
    ('Premium Tank A',  'premium', 10000, 3200),
    ('Kerosene Tank A', 'kerosene',10000, 2800)
ON CONFLICT DO NOTHING;

SELECT 'Migration completed successfully âœ…' AS status;
