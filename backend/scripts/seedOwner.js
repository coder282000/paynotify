// scripts/seedOwner.js
// Run ONCE to create the initial owner account
// Usage: node scripts/seedOwner.js

require('dotenv').config();
const pool = require('../src/config/database');
const { hashPassword } = require('../src/utils/password');

async function seedOwner() {
    console.log('\n👑 Creating Owner Account...\n');

    try {
        // Check if owner already exists
        const existing = await pool.query(
            'SELECT id, username, email FROM users WHERE role = $1',
            ['owner']
        );

        if (existing.rows.length > 0) {
            console.log('⚠️  Owner account already exists!');
            console.log('─────────────────────────────────────────────');
            console.log(`   🆔 ID: ${existing.rows[0].id}`);
            console.log(`   👤 Username: ${existing.rows[0].username}`);
            console.log(`   📧 Email: ${existing.rows[0].email || 'Not set'}`);
            console.log('─────────────────────────────────────────────');
            console.log('\n💡 To reset, delete the owner user first:');
            console.log('   DELETE FROM users WHERE role = \'owner\';');
            console.log('   (This will also delete their stations and employees)');
            process.exit(0);
        }

        // Get owner details from environment or use defaults
        const username = process.env.OWNER_USERNAME || 'owner';
        const password = process.env.OWNER_PASSWORD || 'owner123';
        const fullName = process.env.OWNER_FULL_NAME || 'Business Owner';
        const email = process.env.OWNER_EMAIL || 'owner@paynotify.co.ke';
        const phone = process.env.OWNER_PHONE || '+254700000000';

        // Hash password
        const hashedPassword = await hashPassword(password);

        // Create owner account
        const result = await pool.query(
            `INSERT INTO users (username, password_hash, full_name, email, phone, role, is_active)
             VALUES ($1, $2, $3, $4, $5, 'owner', true)
             RETURNING id, username, full_name, email, phone, role, is_active, created_at`,
            [username.toLowerCase(), hashedPassword, fullName, email, phone]
        );

        const owner = result.rows[0];

        console.log('✅ Owner account created successfully!');
        console.log('─────────────────────────────────────────────');
        console.log(`   🆔 ID: ${owner.id}`);
        console.log(`   👤 Username: ${owner.username}`);
        console.log(`   📛 Full Name: ${owner.full_name}`);
        console.log(`   📧 Email: ${owner.email}`);
        console.log(`   📱 Phone: ${owner.phone}`);
        console.log(`   🔑 Password: ${password}`);
        console.log(`   📅 Created: ${owner.created_at}`);
        console.log('─────────────────────────────────────────────');
        console.log('\n⚠️  IMPORTANT: Change password after first login!');
        console.log('\n📋 Next Steps:');
        console.log('   1. Login with the credentials above');
        console.log('   2. Create your first station');
        console.log('   3. Invite your manager via email');
        console.log('   4. Start managing employees!');

        await pool.end();

    } catch (err) {
        console.error('❌ Seed failed:', err.message);
        console.error('   Check your database connection and .env file.');
        process.exit(1);
    }
}

seedOwner();