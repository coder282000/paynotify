// scripts/seedUsers.js
// Run ONCE to populate users with properly hashed passwords:
//   node scripts/seedUsers.js

require('dotenv').config();
const pool = require('../src/config/database');
const { hashPassword } = require('../src/utils/password');

const DEMO_USERS = [
    // Owner
    { username: 'owner',       password: 'owner123',   full_name: 'Business Owner',     role: 'owner' },
    
    // Manager
    { username: 'manager',     password: 'manager123', full_name: 'Station Manager',     role: 'manager' },
    
    // Supervisors
    { username: 'supervisor1', password: 'super123',   full_name: 'John Supervisor',     role: 'supervisor' },
    { username: 'supervisor2', password: 'super456',   full_name: 'Mary Gathoni',        role: 'supervisor' },
    { username: 'mike',        password: 'super789',   full_name: 'Mike Otieno',         role: 'supervisor' },
    
    // Attendants
    { username: 'john',        password: 'pump1',      full_name: 'John Attendant',      role: 'attendant' },
    { username: 'mary',        password: 'pump2',      full_name: 'Mary Attendant',      role: 'attendant' },
    { username: 'peter',       password: 'pump3',      full_name: 'Peter Attendant',     role: 'attendant' },
    { username: 'grace',       password: 'pump4',      full_name: 'Grace Attendant',     role: 'attendant' },
];

async function seedUsers() {
    console.log('🔐 Seeding users with bcrypt-hashed passwords...\n');

    for (const u of DEMO_USERS) {
        // Check if user already exists — never blindly delete existing data
        const existing = await pool.query(
            'SELECT id FROM users WHERE username = $1',
            [u.username]
        );

        if (existing.rows.length > 0) {
            console.log(`⏭️  Skipped: ${u.username} (already exists)`);
            continue;
        }

        const hash = await hashPassword(u.password);

        await pool.query(
            `INSERT INTO users (username, password_hash, full_name, role, is_active)
             VALUES ($1, $2, $3, $4, true)`,
            [u.username, hash, u.full_name, u.role]
        );

        console.log(`✅ Created: ${u.username.padEnd(14)} [${u.role}]`);
    }

    console.log('\n📋 Demo login credentials:');
    console.log('   👔 Owner:       owner       / owner123');
    console.log('   👔 Manager:     manager     / manager123');
    console.log('   🛡️ Supervisor:  supervisor1 / super123');
    console.log('   🛡️ Supervisor:  supervisor2 / super456');
    console.log('   🛡️ Supervisor:  mike        / super789');
    console.log('   ⛽ Attendant:   john        / pump1');
    console.log('   ⛽ Attendant:   mary        / pump2');
    console.log('   ⛽ Attendant:   peter       / pump3');
    console.log('   ⛽ Attendant:   grace       / pump4');

    // Show all users without exposing hashes
    const all = await pool.query(
        'SELECT id, username, full_name, role, is_active FROM users ORDER BY id'
    );
    console.log('\n👥 All users in database:');
    all.rows.forEach(r =>
        console.log(`   #${String(r.id).padEnd(3)} ${r.username.padEnd(14)} [${r.role}]  ${r.full_name}`)
    );

    await pool.end();
    console.log('\n✅ Seed complete.');
}

seedUsers().catch(err => {
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
});