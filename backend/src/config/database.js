// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

// Validate required env vars at startup — fail fast, fail loud
const required = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
for (const key of required) {
    if (!process.env[key]) {
        console.error(`❌ Missing required environment variable: ${key}`);
        console.error('   Check your .env file.');
        process.exit(1);
    }
}

const pool = new Pool({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    // Connection pool settings
    max: 10,                // Max simultaneous connections
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
});

// Test connection on startup
pool.connect((err, client, release) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
        console.error('   Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME in .env');
        process.exit(1);
    } else {
        console.log('✅ Connected to PostgreSQL database');
        release();
    }
});

// Handle pool errors gracefully
pool.on('error', (err) => {
    console.error('Unexpected database pool error:', err.message);
});

module.exports = pool;
