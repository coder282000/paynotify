// testEmail.js
require('dotenv').config();
const { sendInvitationEmail } = require('./src/utils/email');

async function testEmail() {
    console.log('📧 Testing email sending...\n');
    
    try {
        await sendInvitationEmail(
            'levikim090@gmail.com',
            'Test User',
            'attendant',
            'Test Station',
            'Owner',
            'test-token-123'
        );
        console.log('\n✅ Test completed successfully!');
    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
        process.exit(1);
    }
}

testEmail();