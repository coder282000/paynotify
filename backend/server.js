// server.js - PayNotify Backend

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const pool = require('./src/config/database');

const authRoutes = require('./src/routes/authRoutes');
const pumpRoutes = require('./src/routes/pumpRoutes');
const transactionRoutes = require('./src/routes/transactionRoutes');
const stationRoutes = require('./src/routes/stationRoutes');
const employeeRoutes = require('./src/routes/employeeRoutes');
const publicRoutes = require('./src/routes/publicRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// ── RATE LIMITING ────────────────────────────────────────────────────
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: 'Too many requests, please try again later.'
});

// ── CORS CONFIGURATION ──────────────────────────────────────────────
const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:3001',
    'https://unlatch-joystick-grievance.ngrok-free.dev',
    'https://paynotify-production.up.railway.app',
    process.env.FRONTEND_URL,
].filter(Boolean);

app.use(cors({
    origin: function(origin, callback) {
        if (!origin) return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
            callback(null, true);
        } else {
            console.warn('CORS blocked:', origin);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning', 'Accept'],
}));

app.set('trust proxy', 1);

// ── SECURITY MIDDLEWARE ──────────────────────────────────────────────
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: [
                "'self'",
                "'unsafe-inline'",
                "'unsafe-eval'",
                "'wasm-unsafe-eval'",
                "https://www.gstatic.com",
                "https://unlatch-joystick-grievance.ngrok-free.dev",
                "https://paynotify-production.up.railway.app",
                "https://fonts.googleapis.com",
            ],
            styleSrc: [
                "'self'",
                "'unsafe-inline'",
                "https://fonts.googleapis.com",
                "https://unlatch-joystick-grievance.ngrok-free.dev",
                "https://paynotify-production.up.railway.app",
            ],
            imgSrc: ["'self'", "data:", "https:", "blob:"],
            fontSrc: [
                "'self'",
                "https://fonts.gstatic.com",
                "https://fonts.googleapis.com",
                "data:",
            ],
            connectSrc: [
                "'self'",
                "https://unlatch-joystick-grievance.ngrok-free.dev",
                "https://paynotify-production.up.railway.app",
                "https://www.gstatic.com",
                "https://fonts.gstatic.com",
                "https://fonts.googleapis.com",
                "http://localhost:3000",
                "http://localhost:3001",
                "blob:",
                "https://*.googleapis.com",
                "https://*.gstatic.com",
            ],
            workerSrc: ["'self'", "blob:"],
            mediaSrc: ["'self'", "blob:"],
            objectSrc: ["'none'"],
            frameSrc: ["'self'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
            upgradeInsecureRequests: [],
        },
    },
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
    crossOriginOpenerPolicy: { policy: "unsafe-none" },
}));

app.use(limiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── LOGGING ─────────────────────────────────────────────────────────
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// ── STATIC FILES ───────────────────────────────────────────────────
const downloadsPath = path.join(__dirname, 'public', 'downloads');
if (!fs.existsSync(downloadsPath)) {
    fs.mkdirSync(downloadsPath, { recursive: true });
}
app.use('/downloads', express.static(downloadsPath));

// 🔍 DEBUGGING: Find Flutter Web Build
console.log('🔍 ========================================');
console.log('🔍 DEBUGGING FLUTTER WEB PATH');
console.log('🔍 ========================================');
console.log('📁 __dirname:', __dirname);
console.log('📁 process.cwd():', process.cwd());
console.log('📁 NODE_ENV:', process.env.NODE_ENV);

// Check what's in the parent directory
const parentDir = path.join(__dirname, '..');
console.log('📁 Parent directory:', parentDir);
console.log('📁 Parent exists?', fs.existsSync(parentDir));

if (fs.existsSync(parentDir)) {
    const contents = fs.readdirSync(parentDir);
    console.log('📁 Contents of parent directory:', contents);
}

// Check for frontend folder
const frontendPath = path.join(__dirname, '..', 'frontend');
console.log('📁 Frontend path:', frontendPath);
console.log('📁 Frontend exists?', fs.existsSync(frontendPath));

let flutterWebPath = null;
let webBuildFound = false;

// Try multiple possible paths
const possiblePaths = [
    path.join(__dirname, '..', 'frontend', 'build', 'web'),
    path.join(process.cwd(), 'frontend', 'build', 'web'),
    path.join(__dirname, 'frontend', 'build', 'web'),
    path.join('/', 'frontend', 'build', 'web'),
    path.join(__dirname, '..', '..', 'frontend', 'build', 'web'),
    path.join(__dirname, 'flutter_web'),
    path.join(process.cwd(), 'build', 'web'),
];

console.log('📁 Checking possible paths:');
for (const p of possiblePaths) {
    const exists = fs.existsSync(p);
    console.log(`   ${exists ? '✅' : '❌'} ${p}`);
    if (exists) {
        flutterWebPath = p;
        webBuildFound = true;
        console.log(`   ✅ FOUND at: ${p}`);
        // List contents
        try {
            const files = fs.readdirSync(p);
            console.log(`   📁 Contents: ${files.slice(0, 10).join(', ')}${files.length > 10 ? '...' : ''}`);
        } catch (e) {
            console.log(`   ⚠️ Could not read contents: ${e.message}`);
        }
        break;
    }
}

// If frontend exists but build/web doesn't, check what's in frontend
if (fs.existsSync(frontendPath) && !webBuildFound) {
    try {
        const frontendContents = fs.readdirSync(frontendPath);
        console.log('📁 Contents of frontend:', frontendContents);
        
        // Check if build folder exists
        const buildPath = path.join(frontendPath, 'build');
        if (fs.existsSync(buildPath)) {
            console.log('📁 Build folder exists! Contents:');
            const buildContents = fs.readdirSync(buildPath);
            console.log('   ', buildContents);
        } else {
            console.log('📁 Build folder does NOT exist in frontend');
        }
    } catch (e) {
        console.log('⚠️ Could not read frontend contents:', e.message);
    }
}

// Use the found path or fallback
const FLUTTER_WEB_BUILD = flutterWebPath || path.join(__dirname, '..', 'frontend', 'build', 'web');
const hasFlutterWeb = webBuildFound || fs.existsSync(FLUTTER_WEB_BUILD);

console.log('🔍 ========================================');
console.log(`🔍 Final FLUTTER_WEB_BUILD: ${FLUTTER_WEB_BUILD}`);
console.log(`🔍 hasFlutterWeb: ${hasFlutterWeb}`);
console.log('🔍 ========================================');

if (hasFlutterWeb) {
    app.use(express.static(FLUTTER_WEB_BUILD));
    console.log(`✅ Flutter web build found at: ${FLUTTER_WEB_BUILD}`);
} else {
    console.log(`⚠️  Flutter web build not found at: ${FLUTTER_WEB_BUILD}`);
    console.log('   Run: flutter build web');
}

// ── REGISTRATION ROUTE ─────────────────────────────────────────────
app.get('/register', async (req, res) => {
    try {
        const { token } = req.query;
        console.log(`📝 Registration request with token: ${token}`);

        // TEST MODE: Bypass for testing
        if (token === 'test123' || token === 'test' || token === 'dev') {
            console.log('🧪 TEST MODE: Bypassing token validation');
            
            if (hasFlutterWeb) {
                const indexPath = path.join(FLUTTER_WEB_BUILD, 'index.html');
                console.log(`📄 TEST MODE: Serving from: ${indexPath}`);
                
                try {
                    let html = fs.readFileSync(indexPath, 'utf8');
                    html = html.replace(
                        '</head>',
                        `<script>
                            window.REGISTRATION_TOKEN = "${token}";
                            window.INVITATION_DATA = {
                                email: "test@example.com",
                                fullName: "Test User",
                                role: "attendant",
                                stationName: "Test Station",
                                stationId: "1",
                                phone: "0712345678",
                                expiresAt: "${new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString()}"
                            };
                            console.log('🧪 TEST MODE: Registration token loaded');
                        </script>
                        </head>`
                    );
                    return res.send(html);
                } catch (fileError) {
                    console.error('❌ Error reading index.html:', fileError);
                }
            }
            
            // Fallback redirect
            return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3001'}/#/register?token=${token}`);
        }

        if (!token) {
            console.log('❌ No token provided');
            return res.status(400).send(`
                <!DOCTYPE html>
                <html>
                    <head>
                        <title>Invalid Registration Link</title>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>
                            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; margin: 0; }
                            .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                            h1 { color: #d32f2f; margin-top: 0; }
                            .btn { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: 500; }
                            .icon { font-size: 48px; }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="icon">🔗</div>
                            <h1>Invalid Registration Link</h1>
                            <p>No registration token provided. Please check your invitation email or contact your employer.</p>
                            <a href="${process.env.FRONTEND_URL || '/'}" class="btn">Return to Home</a>
                        </div>
                    </body>
                </html>
            `);
        }

        const result = await pool.query(
            `SELECT 
                ei.id,
                ei.email,
                ei.full_name,
                ei.role,
                ei.station_id,
                ei.phone,
                ei.employee_role,
                ei.assigned_pump_id,
                ei.status,
                ei.expires_at,
                s.station_name,
                u.full_name as invited_by_name
             FROM employee_invitations ei
             LEFT JOIN stations s ON s.id = ei.station_id
             LEFT JOIN users u ON u.id = ei.invited_by
             WHERE ei.token = $1 
             AND ei.expires_at > NOW() 
             AND ei.status = 'pending'`,
            [token]
        );

        console.log(`📊 Query result: ${result.rows.length} rows found`);

        if (result.rows.length === 0) {
            const expiredCheck = await pool.query(
                `SELECT * FROM employee_invitations WHERE token = $1`,
                [token]
            );

            let errorMessage = 'This registration link is invalid.';
            if (expiredCheck.rows.length > 0) {
                const invitation = expiredCheck.rows[0];
                if (invitation.status === 'used') {
                    errorMessage = 'This registration link has already been used.';
                } else if (new Date(invitation.expires_at) < new Date()) {
                    errorMessage = 'This registration link has expired (48-hour window).';
                }
            }

            console.log(`❌ Invalid or expired token: ${errorMessage}`);

            return res.status(400).send(`
                <!DOCTYPE html>
                <html>
                    <head>
                        <title>Invalid Registration Link</title>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>
                            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; margin: 0; }
                            .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                            h1 { color: #f57c00; margin-top: 0; }
                            .btn { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: 500; }
                            .icon { font-size: 48px; }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="icon">⏰</div>
                            <h1>${expiredCheck.rows.length > 0 && expiredCheck.rows[0].status === 'used' ? 'Already Used' : 'Link Expired'}</h1>
                            <p>${errorMessage}</p>
                            <p style="color: #666; font-size: 14px;">Please contact your employer to request a new invitation.</p>
                            <a href="${process.env.FRONTEND_URL || '/'}" class="btn">Return to Home</a>
                        </div>
                    </body>
                </html>
            `);
        }

        const invitation = result.rows[0];
        console.log(`✅ Valid invitation for: ${invitation.email} (${invitation.role})`);

        if (hasFlutterWeb) {
            const indexPath = path.join(FLUTTER_WEB_BUILD, 'index.html');
            console.log(`📄 Serving index.html from: ${indexPath}`);

            try {
                let html = fs.readFileSync(indexPath, 'utf8');
                html = html.replace(
                    '</head>',
                    `<script>
                        window.REGISTRATION_TOKEN = "${token}";
                        window.INVITATION_DATA = {
                            email: "${invitation.email}",
                            fullName: "${invitation.full_name}",
                            role: "${invitation.role}",
                            stationName: "${invitation.station_name || ''}",
                            stationId: "${invitation.station_id || ''}",
                            phone: "${invitation.phone || ''}",
                            expiresAt: "${invitation.expires_at}"
                        };
                        console.log('✅ Registration token loaded:', window.REGISTRATION_TOKEN);
                        console.log('✅ Invitation data:', window.INVITATION_DATA);
                    </script>
                    </head>`
                );
                return res.send(html);
            } catch (fileError) {
                console.error('❌ Error reading index.html:', fileError);
            }
        }

        const redirectUrl = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/#/register?token=${token}`;
        console.log(`🔄 Redirecting to: ${redirectUrl}`);
        res.redirect(redirectUrl);

    } catch (error) {
        console.error('❌ Registration route error:', error);
        console.error('Stack:', error.stack);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Error</title>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; margin: 0; }
                        .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                        h1 { color: #d32f2f; margin-top: 0; }
                        .btn { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: 500; }
                        .icon { font-size: 48px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="icon">⚠️</div>
                        <h1>Something Went Wrong</h1>
                        <p>We encountered an error processing your registration link.</p>
                        <p style="color: #666; font-size: 14px;">Please try again or contact support.</p>
                        <a href="${process.env.FRONTEND_URL || '/'}" class="btn">Return to Home</a>
                    </div>
                </body>
            </html>
        `);
    }
});

// ── APK DOWNLOAD ENDPOINT ──────────────────────────────────────────
app.get('/api/download/app', (req, res) => {
    const apkPath = path.join(__dirname, 'public', 'downloads', 'paynotify.apk');

    if (!fs.existsSync(apkPath)) {
        return res.status(404).json({
            success: false,
            message: 'App download not available yet.'
        });
    }

    const userAgent = req.headers['user-agent'] || 'unknown';
    const ip = req.ip || req.connection.remoteAddress;
    console.log(`📱 APK Download: ${ip} - ${userAgent}`);

    res.download(apkPath, 'PayNotify.apk', (err) => {
        if (err) {
            console.error('Download error:', err);
            res.status(500).json({
                success: false,
                message: 'Download failed. Please try again.'
            });
        }
    });
});

// ── INFO ENDPOINT ──────────────────────────────────────────────────
app.get('/api/info', (req, res) => {
    res.json({
        name: 'PayNotify Backend',
        version: '1.0.0',
        status: 'running',
        time: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        flutter_web_available: hasFlutterWeb,
        endpoints: {
            health: 'GET /api/health',
            info: 'GET /api/info',
            login: 'POST /api/auth/login',
            register: 'GET /register?token=xxx',
            invite_validate: 'GET /api/public/invite/:token',
            employee_register: 'POST /api/public/register',
            employees: 'GET /api/employees',
            stations: 'GET /api/stations',
            pumps: 'GET /api/pumps',
            transactions: 'GET /api/transactions',
            download: 'GET /downloads/paynotify.apk',
            download_api: 'GET /api/download/app'
        }
    });
});

// ── HEALTH CHECK ────────────────────────────────────────────────────
app.get('/api/health', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');
        res.json({
            status: 'healthy',
            database: 'connected',
            time: result.rows[0].now,
            uptime: process.uptime(),
            flutter_web: hasFlutterWeb
        });
    } catch (err) {
        res.status(500).json({
            status: 'unhealthy',
            database: 'disconnected',
            error: err.message
        });
    }
});

// ── API ROUTES ──────────────────────────────────────────────────────
app.use('/api/public', publicRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/pumps', pumpRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/stations', stationRoutes);
app.use('/api/employees', employeeRoutes);

// ── SPA CATCH-ALL ──────────────────────────────────────────────────
app.use((req, res, next) => {
    if (req.path.startsWith('/api') || req.path.startsWith('/downloads')) {
        return next();
    }

    if (path.extname(req.path) !== '') {
        return next();
    }

    if (req.path === '/register') {
        return next();
    }

    if (hasFlutterWeb) {
        const indexPath = path.join(FLUTTER_WEB_BUILD, 'index.html');
        if (fs.existsSync(indexPath)) {
            return res.sendFile(indexPath);
        }
    }

    if (process.env.NODE_ENV === 'development' && process.env.FRONTEND_URL) {
        if (req.path === '/favicon.ico') {
            return res.status(204).end();
        }
        return res.redirect(`${process.env.FRONTEND_URL}${req.path}`);
    }

    res.status(404).json({
        success: false,
        message: `Route ${req.method} ${req.url} not found`
    });
});

// ── 404 HANDLER ─────────────────────────────────────────────────────
app.use((req, res) => {
    console.log(`404: ${req.method} ${req.url} not found`);
    res.status(404).json({
        success: false,
        message: `Route ${req.method} ${req.url} not found`
    });
});

// ── ERROR HANDLER ──────────────────────────────────────────────────
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// ── START SERVER ────────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`
    ╔══════════════════════════════════════════════════════════════════╗
    ║                     PayNotify Backend Started!                   ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║  🖥️  Server:      http://localhost:${PORT}                         ║
    ║  📡 Health:      http://localhost:${PORT}/api/health              ║
    ║  📝 Register:    http://localhost:${PORT}/register?token=xxx      ║
    ║  🔐 Login:       POST http://localhost:${PORT}/api/auth/login     ║
    ║  📱 APK:         ${process.env.APK_DOWNLOAD_URL || `http://localhost:${PORT}/downloads/paynotify.apk`}
    ║  🌐 Flutter Web: ${hasFlutterWeb ? '✅ Available' : '❌ Not built'} ║
    ║  📦 Env:         ${process.env.NODE_ENV || 'development'}          ║
    ╚══════════════════════════════════════════════════════════════════╝
    `);
});

// ── GRACEFUL SHUTDOWN ──────────────────────────────────────────────
process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down gracefully...');
    await pool.end();
    console.log('✅ Database connections closed');
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Shutting down gracefully...');
    await pool.end();
    console.log('✅ Database connections closed');
    process.exit(0);
});

process.on('unhandledRejection', (err) => {
    console.error('Unhandled Promise Rejection:', err);
});

process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});