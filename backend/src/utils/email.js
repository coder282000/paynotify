// src/utils/email.js
const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    secure: process.env.SMTP_PORT === '465',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
    connectionTimeout: 30000,
    greetingTimeout: 30000,
    socketTimeout: 30000,
    tls: {
        rejectUnauthorized: false,
    },
});

// Verify transporter connection on startup
transporter.verify((error, success) => {
    if (error) {
        console.error('❌ Email transporter error:', error.message);
        console.error('   Please check your SMTP settings in .env');
    } else {
        console.log('✅ Email transporter ready');
    }
});

/**
 * Send invitation email
 */
const sendInvitationEmail = async (email, fullName, role, stationName, invitedBy, token) => {
    const registrationLink = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/register?token=${token}`;
    
    const playStoreLink = process.env.PLAY_STORE_LINK || 'https://play.google.com/store/apps/details?id=com.paynotify.app';
    const appStoreLink = process.env.APP_STORE_LINK || 'https://apps.apple.com/app/paynotify/id123456789';
    const apkDownloadLink = process.env.APK_DOWNLOAD_URL || 'https://paynotify.co.ke/download/paynotify.apk';
    const desktopLink = process.env.DESKTOP_DOWNLOAD_LINK || 'https://paynotify.co.ke/download/desktop';
    const privacyPolicy = process.env.PRIVACY_POLICY_URL || 'https://paynotify.co.ke/privacy';
    const termsOfService = process.env.TERMS_OF_SERVICE_URL || 'https://paynotify.co.ke/terms';
    const year = new Date().getFullYear();

    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>You're invited to PayNotify!</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #0B3D2E; color: white; padding: 30px 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 28px; }
        .header p { margin: 5px 0 0; opacity: 0.9; font-size: 14px; }
        .content { padding: 30px 20px; }
        .content h2 { color: #0B3D2E; margin-top: 0; }
        .button { display: inline-block; background: #0B3D2E; color: white; padding: 14px 32px; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 10px 0; }
        .button:hover { background: #1A5D4A; }
        .divider { border-top: 2px solid #e9ecef; margin: 30px 0; }
        .app-links { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .app-links h3 { margin-top: 0; color: #0B3D2E; }
        .badge { display: inline-block; background: #2ECC71; color: white; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; }
        .features-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin: 20px 0; }
        .feature-item { background: #f8f9fa; padding: 10px; border-radius: 4px; text-align: center; font-size: 13px; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; border-top: 1px solid #e9ecef; }
        .footer a { color: #0B3D2E; text-decoration: none; }
        .help-box { margin: 20px 0; padding: 15px; background: #fff3cd; border-radius: 6px; border-left: 4px solid #ffc107; }
        .help-box a { color: #0B3D2E; }
        .download-card { background: #e3f2fd; padding: 16px; border-radius: 8px; margin: 12px 0; }
        .download-card h4 { margin: 0 0 8px 0; color: #0B3D2E; }
        .download-btn { display: inline-block; background: #0B3D2E; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: 600; font-size: 14px; margin: 4px; }
        .download-btn:hover { background: #1A5D4A; }
        .platform-badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 600; margin-left: 6px; }
        .platform-android { background: #a4c639; color: white; }
        .platform-ios { background: #555; color: white; }
        .platform-desktop { background: #2196F3; color: white; }
        .platform-web { background: #4CAF50; color: white; }
        @media (max-width: 480px) {
            .features-grid { grid-template-columns: 1fr; }
            .container { margin: 10px; padding: 10px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⛽ PayNotify</h1>
            <p>Petrol Station Management Platform</p>
        </div>
        <div class="content">
            <h2>Hello ${fullName}! 👋</h2>
            <p>You have been invited to join <strong>PayNotify</strong> as a <strong><span class="badge">${role}</span></strong> at <strong>${stationName}</strong>.</p>
            <p style="background: #e8f5e9; padding: 12px; border-radius: 6px; border-left: 4px solid #2ECC71;">
                ✅ Your invitation was sent by <strong>${invitedBy}</strong>
            </p>
            <div style="text-align: center; margin: 30px 0;">
                <a href="${registrationLink}" class="button">✅ Complete Your Registration</a>
                <p style="font-size: 13px; color: #888; margin-top: 8px;">
                    ⏰ This link expires in <strong>48 hours</strong>
                </p>
            </div>
            <div style="margin: 30px 0;">
                <h3>📋 What happens next?</h3>
                <div class="features-grid">
                    <div class="feature-item">📝 Register your account</div>
                    <div class="feature-item">⏳ ${role === 'manager' ? 'Owner' : 'Manager'} approves your account</div>
                    <div class="feature-item">📱 Download the app</div>
                    <div class="feature-item">🚀 Start working!</div>
                </div>
            </div>
            <div class="divider"></div>
            <div class="app-links">
                <h3>📱 Download PayNotify</h3>
                <p style="font-size: 14px; color: #666;">Choose your platform to get started:</p>
                <div class="download-card">
                    <h4>📱 Mobile App</h4>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 8px 0;">
                        <a href="${playStoreLink}" class="download-btn" target="_blank">📲 Play Store</a>
                        <a href="${apkDownloadLink}" class="download-btn" target="_blank">📥 APK Direct</a>
                        <a href="${appStoreLink}" class="download-btn" target="_blank">🍎 App Store</a>
                    </div>
                    <p style="font-size: 12px; color: #888; margin: 4px 0;">💡 Attendants: Use the mobile app for daily operations</p>
                </div>
                <div class="download-card" style="background: #e8f5e9;">
                    <h4>💻 Desktop / Web App</h4>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 8px 0;">
                        <a href="${desktopLink}" class="download-btn" target="_blank">🖥️ Desktop App</a>
                        <a href="${process.env.FRONTEND_URL}" class="download-btn" target="_blank">🌐 Web App</a>
                    </div>
                    <p style="font-size: 12px; color: #888; margin: 4px 0;">💡 Managers & Owners: Use the web app for full management</p>
                </div>
            </div>
            <div class="divider"></div>
            <div style="font-size: 13px; color: #666;">
                <h4>📋 App Requirements:</h4>
                <ul style="padding-left: 20px;">
                    <li><strong>Android:</strong> Version 7.0 or higher</li>
                    <li><strong>iOS:</strong> Version 14.0 or higher</li>
                    <li><strong>Desktop:</strong> Modern browser (Chrome, Firefox, Edge, Safari)</li>
                    <li>📶 Internet connection required</li>
                </ul>
            </div>
            <div class="help-box">
                <p style="margin: 0; font-size: 14px;">
                    <strong>❓ Need help?</strong> Contact your manager or 
                    <a href="mailto:support@paynotify.co.ke">support@paynotify.co.ke</a>
                </p>
            </div>
        </div>
        <div class="footer">
            <p><strong>PayNotify</strong> - Petrol Station Management</p>
            <p>
                <a href="${privacyPolicy}">Privacy Policy</a> • 
                <a href="${termsOfService}">Terms of Service</a>
            </p>
            <p>This is an automated message, please do not reply.</p>
            <p style="font-size: 11px; color: #aaa;">© ${year} PayNotify. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    `;

    const textContent = `
PayNotify - You're Invited!

Hello ${fullName}! 👋

You have been invited to join PayNotify as a ${role} at ${stationName}.

✅ Complete Your Registration:
${registrationLink}

⏰ This link expires in 48 hours

📋 What happens next?
1. Register your account
2. ${role === 'manager' ? 'Owner' : 'Manager'} approves your account
3. Download the app
4. Start working!

📱 Download PayNotify:
Android (Play Store): ${playStoreLink}
Android (APK Direct): ${apkDownloadLink}
iOS (App Store): ${appStoreLink}
Web App: ${process.env.FRONTEND_URL}
Desktop: ${desktopLink}

❓ Need help? Contact support@paynotify.co.ke

---
PayNotify - Petrol Station Management
© ${year} PayNotify. All rights reserved.
    `;

    try {
        console.log(`📧 Sending email to ${email}...`);
        
        const info = await transporter.sendMail({
            from: `"PayNotify" <${process.env.SMTP_FROM}>`,
            to: email,
            subject: `You're invited to join PayNotify as a ${role}! 🚀`,
            html: htmlContent,
            text: textContent,
        });

        console.log(`✅ Email sent to ${email}`);
        console.log(`   Message ID: ${info.messageId}`);
        return { success: true, attempt: 1 };
    } catch (error) {
        console.error(`❌ Email failed for ${email}:`, error.message);
        console.error('   Error code:', error.code);
        console.error('   Command:', error.command);
        
        if (error.message.includes('Invalid login')) {
            console.error('\n💡 Fix: Check your Gmail app password');
            console.error('   Enable 2FA and generate an App Password');
            console.error('   Current SMTP_USER:', process.env.SMTP_USER);
        }
        throw error;
    }
};

/**
 * Send invitation email with retry logic (3 attempts)
 */
const sendInvitationEmailWithRetry = async (email, fullName, role, stationName, invitedBy, token) => {
    let lastError;
    let lastAttempt = 0;
    
    for (let attempt = 1; attempt <= 3; attempt++) {
        try {
            console.log(`📧 Sending email to ${email} (Attempt ${attempt}/3)...`);
            
            const result = await sendInvitationEmail(email, fullName, role, stationName, invitedBy, token);
            
            console.log(`✅ Email sent to ${email}`);
            return { success: true, attempt };
            
        } catch (error) {
            lastError = error;
            lastAttempt = attempt;
            console.error(`❌ Attempt ${attempt} failed:`, error.message);
            
            if (attempt < 3) {
                const waitTime = attempt * 2000;
                console.log(`⏳ Retrying in ${waitTime/1000}s...`);
                await new Promise(resolve => setTimeout(resolve, waitTime));
            }
        }
    }
    
    console.error(`❌ Email permanently failed for ${email} after 3 attempts`);
    return { success: false, error: lastError, attempt: lastAttempt };
};

/**
 * Send account approval email to employee
 */
const sendApprovalEmail = async (email, fullName, username, role, stationName, frontendUrl) => {
    const loginUrl = `${frontendUrl}/login`;
    const downloadUrl = process.env.APK_DOWNLOAD_URL || `${frontendUrl}/downloads/paynotify.apk`;
    const year = new Date().getFullYear();

    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Approved - PayNotify</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #0B3D2E; color: white; padding: 30px 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 28px; }
        .header p { margin: 5px 0 0; opacity: 0.9; font-size: 14px; }
        .content { padding: 30px 20px; }
        .content h2 { color: #0B3D2E; margin-top: 0; }
        .button { display: inline-block; background: #0B3D2E; color: white; padding: 14px 32px; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 10px 0; }
        .button:hover { background: #1A5D4A; }
        .divider { border-top: 2px solid #e9ecef; margin: 30px 0; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; border-top: 1px solid #e9ecef; }
        .badge { display: inline-block; background: #2ECC71; color: white; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; }
        .credentials { background: #f8f9fa; padding: 16px; border-radius: 8px; margin: 16px 0; }
        .credentials code { background: #e9ecef; padding: 2px 8px; border-radius: 4px; font-size: 14px; }
        .help-box { margin: 20px 0; padding: 15px; background: #fff3cd; border-radius: 6px; border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⛽ PayNotify</h1>
            <p>Petrol Station Management Platform</p>
        </div>
        <div class="content">
            <h2>Welcome to PayNotify, ${fullName}! 🎉</h2>
            
            <p style="background: #e8f5e9; padding: 12px; border-radius: 6px; border-left: 4px solid #2ECC71;">
                ✅ Your account has been <strong>approved</strong>!
            </p>
            
            <p>Your manager/owner has approved your registration. You can now log in and start working.</p>
            
            <div class="credentials">
                <h4>📋 Your Account Details:</h4>
                <p style="margin: 4px 0;"><strong>Username:</strong> <code>${username}</code></p>
                <p style="margin: 4px 0;"><strong>Role:</strong> <span class="badge">${role}</span></p>
                <p style="margin: 4px 0;"><strong>Station:</strong> ${stationName || 'N/A'}</p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="${loginUrl}" class="button">🔐 Login Now</a>
            </div>
            
            <div class="divider"></div>
            
            <h3>📱 Download the App</h3>
            <p>Get the best experience by downloading our mobile app:</p>
            
            <div style="text-align: center; margin: 16px 0;">
                <a href="${downloadUrl}" class="button" style="background: #1976D2;">
                    📥 Download APK
                </a>
            </div>
            
            <p style="font-size: 13px; color: #888; text-align: center;">
                📲 You can also search <strong>"PayNotify"</strong> in your app store
            </p>
            
            <div class="divider"></div>
            
            <h4>📋 What can you do now?</h4>
            <ul style="padding-left: 20px;">
                <li>✅ Log in to your account</li>
                <li>📱 Download the mobile app</li>
                <li>⛽ Start recording transactions</li>
                <li>📊 View your performance</li>
            </ul>
            
            <div class="help-box">
                <p style="margin: 0; font-size: 14px;">
                    <strong>❓ Need help?</strong> Contact your manager or 
                    <a href="mailto:support@paynotify.co.ke" style="color: #0B3D2E;">support@paynotify.co.ke</a>
                </p>
            </div>
        </div>
        <div class="footer">
            <p><strong>PayNotify</strong> - Petrol Station Management</p>
            <p style="font-size: 11px; color: #aaa;">© ${year} PayNotify. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    `;

    const textContent = `
PayNotify - Account Approved!

Welcome to PayNotify, ${fullName}! 🎉

✅ Your account has been approved!

Your Account Details:
- Username: ${username}
- Role: ${role}
- Station: ${stationName || 'N/A'}

🔐 Login Now: ${loginUrl}

📱 Download the App:
APK: ${downloadUrl}

📋 What can you do now?
- Log in to your account
- Download the mobile app
- Start recording transactions
- View your performance

❓ Need help? Contact support@paynotify.co.ke

---
PayNotify - Petrol Station Management
© ${year} PayNotify. All rights reserved.
    `;

    await transporter.sendMail({
        from: `"PayNotify" <${process.env.SMTP_FROM}>`,
        to: email,
        subject: `🎉 Welcome to PayNotify, ${fullName}! Your account is approved.`,
        html: htmlContent,
        text: textContent,
    });
};

module.exports = { 
    sendInvitationEmail,
    sendInvitationEmailWithRetry,
    sendApprovalEmail  // ✅ ADDED
};