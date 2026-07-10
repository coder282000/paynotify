// src/utils/email.js
const { Resend } = require('resend');

// Initialize Resend with API key from environment
const resend = new Resend(process.env.RESEND_API_KEY);

// Helper to get base URL
const getBaseUrl = () => {
    return process.env.FRONTEND_URL || 'http://localhost:3001';
};

// Helper to get APK download URL
const getApkUrl = () => {
    return process.env.APK_DOWNLOAD_URL || 'https://github.com/coder282000/paynotify-releases/releases/download/v1.0.0/paynotify.apk';
};

// ✅ UPDATED: Use verified domain instead of onboarding@resend.dev
const getFromAddress = () => {
    return process.env.SMTP_FROM || 'noreply@paynotfy.dpdns.org';
};

// Log transporter status
console.log('✅ Email transporter ready (Resend API)');

/**
 * Send invitation email
 */
const sendInvitationEmail = async (email, fullName, role, stationName, invitedBy, token) => {
    const registrationLink = `${getBaseUrl()}/register?token=${token}`;
    const directApkLink = getApkUrl();
    const downloadPageLink = directApkLink;
    const playStoreLink = process.env.PLAY_STORE_LINK || 'https://play.google.com/store/apps/details?id=com.paynotify.app';
    const appStoreLink = process.env.APP_STORE_LINK || 'https://apps.apple.com/app/paynotify/id123456789';
    const desktopLink = process.env.DESKTOP_DOWNLOAD_LINK || 'https://paynotfy.dpdns.org/download/desktop';
    const privacyPolicy = process.env.PRIVACY_POLICY_URL || 'https://paynotfy.dpdns.org/privacy';
    const termsOfService = process.env.TERMS_OF_SERVICE_URL || 'https://paynotfy.dpdns.org/terms';
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
        .btn-download { display: inline-block; background: #4CAF50; color: white; padding: 14px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 10px 0; font-size: 16px; }
        .btn-download:hover { background: #45a049; }
        .download-section { background: #e8f5e9; padding: 20px; border-radius: 8px; border: 2px solid #4CAF50; margin: 20px 0; text-align: center; }
        .tip { background: #fff3cd; padding: 12px 16px; border-radius: 8px; margin: 15px 0; font-size: 13px; text-align: left; border-left: 4px solid #ffc107; }
        .tip ul { margin: 6px 0 0 18px; padding: 0; }
        .tip ul li { padding: 2px 0; }
        .samsung-tip { background: #e3f2fd; padding: 12px 16px; border-radius: 8px; margin: 10px 0; font-size: 13px; text-align: left; border-left: 4px solid #1976D2; }
        .direct-link { font-size: 12px; color: #999; margin-top: 10px; word-break: break-all; }
        .direct-link a { color: #0B3D2E; }
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

            <!-- REGISTRATION SECTION - Step 1 (NOW FIRST) -->
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border: 2px solid #0B3D2E;">
                <h3 style="margin-top: 0; color: #0B3D2E;">🔐 Step 1: Complete Your Registration</h3>
                <p>Click the button below to register your account:</p>
                <div style="text-align: center;">
                    <a href="${registrationLink}" class="button">✅ Complete Your Registration</a>
                </div>
                <p style="font-size: 12px; color: #888; margin-top: 5px; text-align: center;">
                    ⏰ This link expires in <strong>48 hours</strong>
                </p>
                <p style="font-size: 12px; color: #666; text-align: center; margin-top: 8px;">
                    💡 You can complete registration on any device — mobile, tablet, or computer.
                </p>
            </div>

            <!-- DOWNLOAD SECTION - Step 2 (NOW SECOND) -->
            <div class="download-section">
                <h3 style="margin-top: 0; color: #2e7d32;">📱 Step 2: Download the App</h3>
                <p>After registering, download the app to start working:</p>
                <a href="${directApkLink}"
                   class="btn-download"
                   target="_blank"
                   rel="noopener noreferrer">
                    📥 Download PayNotify APK
                </a>
                <p style="font-size: 12px; color: #666; margin-top: 5px;">
                    ⚠️ <strong>Android Only:</strong> Enable "Install from Unknown Sources" in Settings → Security
                </p>
                <div class="tip">
                    <strong>💡 Install steps after download:</strong>
                    <ul>
                        <li>Open your <strong>Downloads</strong> folder (or My Files app)</li>
                        <li>Tap <strong>paynotify.apk</strong></li>
                        <li>If prompted, enable <strong>"Install unknown apps"</strong> for your browser</li>
                        <li>Tap <strong>Install</strong></li>
                        <li>Tap <strong>Allow</strong> on any permission requests — these are required for the app to work</li>
                    </ul>
                </div>
                <div class="samsung-tip">
                    📱 <strong>Samsung users:</strong> Use <strong>Samsung Internet</strong> browser (not Chrome) for the most reliable download experience on Samsung devices.
                </div>
                <div class="direct-link">
                    Direct link: <a href="${directApkLink}" target="_blank">${directApkLink}</a>
                </div>
            </div>

            <div class="divider"></div>

            <div style="margin: 20px 0;">
                <h3>📋 What happens next?</h3>
                <div class="features-grid">
                    <div class="feature-item">📝 Register your account</div>
                    <div class="feature-item">📥 Download the app</div>
                    <div class="feature-item">⏳ ${role === 'manager' ? 'Owner' : 'Manager'} approves your account</div>
                    <div class="feature-item">🚀 Start working!</div>
                </div>
            </div>

            <div class="divider"></div>

            <div class="app-links">
                <h3>📱 Other Download Options</h3>
                <p style="font-size: 14px; color: #666;">Choose your platform:</p>
                <div class="download-card">
                    <h4>📱 Mobile App</h4>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 8px 0;">
                        <a href="${playStoreLink}" class="download-btn" target="_blank">📲 Play Store</a>
                        <a href="${directApkLink}" class="download-btn" style="background: #1976D2;" target="_blank">📥 APK Direct</a>
                        <a href="${appStoreLink}" class="download-btn" style="background: #555;" target="_blank">🍎 App Store</a>
                    </div>
                    <p style="font-size: 12px; color: #888; margin: 4px 0;">💡 Attendants: Use the mobile app for daily operations</p>
                </div>
                <div class="download-card" style="background: #e8f5e9;">
                    <h4>💻 Desktop / Web App</h4>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 8px 0;">
                        <a href="${desktopLink}" class="download-btn" style="background: #2196F3;" target="_blank">🖥️ Desktop App</a>
                        <a href="${getBaseUrl()}" class="download-btn" style="background: #4CAF50;" target="_blank">🌐 Web App</a>
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
                    <a href="mailto:support@paynotfy.dpdns.org">support@paynotfy.dpdns.org</a>
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

🔐 Step 1: Complete Your Registration
${registrationLink}

⏰ This link expires in 48 hours
💡 You can complete registration on any device — mobile, tablet, or computer.

📱 Step 2: Download the App (After Registration)
Direct APK Download: ${directApkLink}

Install steps:
1. Open your Downloads folder (or My Files app)
2. Tap paynotify.apk
3. Enable "Install unknown apps" for your browser if prompted
4. Tap Install
5. Tap Allow on any permission requests — these are required for the app to work

📌 Samsung users: Use Samsung Internet browser (not Chrome) for best results.

📋 What happens next?
1. Register your account
2. Download the app
3. ${role === 'manager' ? 'Owner' : 'Manager'} approves your account
4. Start working!

📱 Download PayNotify:
Android (Play Store): ${playStoreLink}
Android (APK Direct): ${directApkLink}
iOS (App Store): ${appStoreLink}
Web App: ${getBaseUrl()}
Desktop: ${desktopLink}

❓ Need help? Contact support@paynotfy.dpdns.org

---
PayNotify - Petrol Station Management
© ${year} PayNotify. All rights reserved.
    `;

    try {
        console.log(`📧 Sending invitation email to ${email}...`);
        const { data, error } = await resend.emails.send({
            from: `PayNotify <${getFromAddress()}>`,
            to: [email],
            subject: `You're invited to join PayNotify as a ${role}! 🚀`,
            html: htmlContent,
            text: textContent,
        });

        if (error) {
            console.error(`❌ Resend API error for ${email}:`, error);
            throw new Error(`Resend API error: ${error.message}`);
        }

        console.log(`✅ Invitation email sent to ${email}`);
        console.log(`   Message ID: ${data?.id}`);
        return { success: true, attempt: 1, messageId: data?.id };
    } catch (error) {
        console.error(`❌ Email failed for ${email}:`, error.message);
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
    const loginUrl = `${frontendUrl || getBaseUrl()}/login`;
    const downloadUrl = getApkUrl();
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
        .btn-download { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: 600; margin: 10px 0; }
        .btn-download:hover { background: #1565C0; }
        .tip { background: #fff3cd; padding: 12px 16px; border-radius: 8px; margin: 15px 0; font-size: 13px; border-left: 4px solid #ffc107; }
        .tip ul { margin: 6px 0 0 18px; padding: 0; }
        .tip ul li { padding: 2px 0; }
        .samsung-tip { background: #e3f2fd; padding: 12px 16px; border-radius: 8px; margin: 10px 0; font-size: 13px; border-left: 4px solid #1976D2; }
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
                <a href="${downloadUrl}" class="btn-download">
                    📥 Download PayNotify APK
                </a>
            </div>

            <div class="tip">
                <strong>💡 Install steps:</strong>
                <ul>
                    <li>Open your <strong>Downloads</strong> folder (or My Files app)</li>
                    <li>Tap <strong>paynotify.apk</strong></li>
                    <li>Enable <strong>"Install unknown apps"</strong> for your browser if prompted</li>
                    <li>Tap <strong>Install</strong></li>
                    <li>Tap <strong>Allow</strong> on any permission requests — these are required for the app to work</li>
                </ul>
            </div>

            <div class="samsung-tip">
                📱 <strong>Samsung users:</strong> Use <strong>Samsung Internet</strong> browser (not Chrome) for the most reliable download experience.
            </div>

            <p style="font-size: 13px; color: #888; text-align: center; margin-top: 12px;">
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
                    <a href="mailto:support@paynotfy.dpdns.org" style="color: #0B3D2E;">support@paynotfy.dpdns.org</a>
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

Install steps:
1. Open your Downloads folder (or My Files app)
2. Tap paynotify.apk
3. Enable "Install unknown apps" for your browser if prompted
4. Tap Install
5. Tap Allow on any permission requests — these are required for the app to work

📌 Samsung users: Use Samsung Internet browser (not Chrome) for best results.

📋 What can you do now?
- Log in to your account
- Download the mobile app
- Start recording transactions
- View your performance

❓ Need help? Contact support@paynotfy.dpdns.org

---
PayNotify - Petrol Station Management
© ${year} PayNotify. All rights reserved.
    `;

    try {
        console.log(`📧 Sending approval email to ${email}...`);
        const { data, error } = await resend.emails.send({
            from: `PayNotify <${getFromAddress()}>`,
            to: [email],
            subject: `🎉 Welcome to PayNotify, ${fullName}! Your account is approved.`,
            html: htmlContent,
            text: textContent,
        });

        if (error) {
            console.error(`❌ Resend API error for ${email}:`, error);
            throw new Error(`Resend API error: ${error.message}`);
        }

        console.log(`✅ Approval email sent to ${email}`);
        console.log(`   Message ID: ${data?.id}`);
        return { success: true, messageId: data?.id };
    } catch (error) {
        console.error(`❌ Approval email failed for ${email}:`, error.message);
        throw error;
    }
};

module.exports = {
    sendInvitationEmail,
    sendInvitationEmailWithRetry,
    sendApprovalEmail
};