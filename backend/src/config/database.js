// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

let pool;

// ── Railway provides DATABASE_URL, local dev uses individual DB_* vars ──
if (process.env.DATABASE_URL) {
    // ✅ PRODUCTION (Railway) — use connection string directly
    console.log('🔌 Using DATABASE_URL for database connection');
    pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: {
            rejectUnauthorized: false  // Required for Railway's PostgreSQL
        },
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
    });
} else {
    // ✅ DEVELOPMENT (local) — use individual DB_* variables
    const required = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
    for (const key of required) {
        if (!process.env[key]) {
            console.error(`❌ Missing required environment variable: ${key}`);
            console.error('   Check your .env file or set DATABASE_URL for production.');
            process.exit(1);
        }
    }

    console.log('🔌 Using individual DB_* variables for database connection');
    pool = new Pool({
        host: process.env.DB_HOST,
        port: parseInt(process.env.DB_PORT, 10),
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
    });
}

// Test connection on startup
pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
        if (!process.env.DATABASE_URL) {
            console.error('   Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME in .env');
        } else {
            console.error('   Check DATABASE_URL is correctly set');
        }
        process.exit(1);
    } else {
        console.log('✅ Connected to PostgreSQL database');
        release();
    }
});

pool.on('error', (err) => {
    console.error('Unexpected database pool error:', err.message);
});

module.exports = pool;