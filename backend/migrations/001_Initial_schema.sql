-- Add these tables to your migration file

-- STATIONS table
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    station_name VARCHAR(100) NOT NULL,
    location VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- EMPLOYEE INVITATIONS table
CREATE TABLE IF NOT EXISTS employee_invitations (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('attendant', 'supervisor', 'manager', 'owner')),
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    phone VARCHAR(20),
    employee_role VARCHAR(30),
    assigned_pump_id INTEGER REFERENCES pumps(id) ON DELETE SET NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'used', 'expired')),
    invited_by INTEGER REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '48 hours'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STATION SETTINGS table
CREATE TABLE IF NOT EXISTS station_settings (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    setting_key VARCHAR(50) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STATION DAILY SUMMARY table
CREATE TABLE IF NOT EXISTS station_daily_summary (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    summary_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_sales NUMERIC(12,2) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    total_liters NUMERIC(10,3) DEFAULT 0,
    cash_total NUMERIC(12,2) DEFAULT 0,
    mpesa_total NUMERIC(12,2) DEFAULT 0,
    card_total NUMERIC(12,2) DEFAULT 0,
    expenses_total NUMERIC(12,2) DEFAULT 0,
    net_profit NUMERIC(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SHIFT SCHEDULES table
CREATE TABLE IF NOT EXISTS shift_schedules (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    employee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    shift_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    role VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OWNER SUBSCRIPTIONS table
CREATE TABLE IF NOT EXISTS owner_subscriptions (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    plan_type VARCHAR(30) NOT NULL CHECK (plan_type IN ('basic', 'premium', 'enterprise')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired')),
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for performance
CREATE INDEX idx_stations_owner_id ON stations(owner_id);
CREATE INDEX idx_invitations_station_id ON employee_invitations(station_id);
CREATE INDEX idx_station_settings_station_id ON station_settings(station_id);
CREATE INDEX idx_daily_summary_station_id ON station_daily_summary(station_id);
CREATE INDEX idx_shift_schedules_station_id ON shift_schedules(station_id);
CREATE INDEX idx_subscriptions_owner_id ON owner_subscriptions(owner_id);
CREATE INDEX idx_subscriptions_station_id ON owner_subscriptions(station_id);