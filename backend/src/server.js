import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';

import db from './config/database.js';
import { verifyToken, verifySocketToken, generateToken } from './middleware/auth.js';
import { encryptField, decryptField } from './utils/encryption.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: process.env.NODE_ENV === 'production' ? 'https://yourdomain.com' : '*',
        methods: ['GET', 'POST']
    }
});

// Security middleware
app.use((req, res, next) => {
    // Skip token verification for device registration
    if (req.path === '/api/device/register') {
        return next();
    }
    verifyToken(req, res, next);
});

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(rateLimit({
    windowMs: process.env.RATE_LIMIT_WINDOW * 60 * 1000,
    max: process.env.RATE_LIMIT_MAX_REQUESTS
}));

// Device Registration and Authentication
app.post('/api/device/register', async (req, res) => {
    try {
        const { deviceId, deviceModel, deviceName, osVersion, screenResolution, appVersion } = req.body;

        // Validate required fields
        if (!deviceId || !deviceModel || !deviceName || !osVersion) {
            return res.status(400).json({ 
                message: 'Missing required fields', 
                required: ['deviceId', 'deviceModel', 'deviceName', 'osVersion'] 
            });
        }

        // Begin transaction
        await db.run('BEGIN TRANSACTION');

        try {
            // Insert or update device
            await db.run(`
                INSERT INTO devices (device_id, last_seen_at)
                VALUES (?, CURRENT_TIMESTAMP)
                ON CONFLICT(device_id) DO UPDATE SET last_seen_at = CURRENT_TIMESTAMP
            `, [deviceId]);

            // Insert or update device info
            await db.run(`
                INSERT INTO device_info (
                    device_id, device_model, device_name, os_version,
                    screen_resolution, app_version, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(device_id) DO UPDATE SET
                    device_model = ?,
                    device_name = ?,
                    os_version = ?,
                    screen_resolution = ?,
                    app_version = ?,
                    updated_at = CURRENT_TIMESTAMP
            `, [
                deviceId,
                encryptField(deviceModel),
                encryptField(deviceName),
                encryptField(osVersion),
                encryptField(screenResolution),
                encryptField(appVersion),
                encryptField(deviceModel),
                encryptField(deviceName),
                encryptField(osVersion),
                encryptField(screenResolution),
                encryptField(appVersion)
            ]);

            // Generate and store token
            const token = generateToken(deviceId);
            await db.run(`
                INSERT INTO auth_tokens (device_id, token)
                VALUES (?, ?)
                ON CONFLICT(device_id) DO UPDATE SET
                    token = ?,
                    created_at = CURRENT_TIMESTAMP
            `, [deviceId, token, token]);

            // Create default device settings if not exists
            await db.run(`
                INSERT INTO device_settings (device_id)
                VALUES (?)
                ON CONFLICT(device_id) DO NOTHING
            `, [deviceId]);

            await db.run('COMMIT');
            res.status(201).json({ token });
        } catch (error) {
            await db.run('ROLLBACK');
            throw error;
        }
    } catch (error) {
        console.error('Error registering device:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Device Info Endpoint
app.post('/api/device/info', verifyToken, async (req, res) => {
    try {
        const {
            id,
            timestamp,
            latitude,
            longitude,
            altitude,
            accuracy,
            batteryLevel,
            deviceId,
            deviceModel,
            deviceName,
            osVersion,
            screenResolution,
            appVersion
        } = req.body;

        // Zorunlu alanları kontrol et
        const requiredFields = ['id', 'deviceId', 'latitude', 'longitude'];
        const missingFields = requiredFields.filter(field => !req.body[field]);
        
        if (missingFields.length > 0) {
            return res.status(400).json({ 
                message: 'Missing required fields', 
                fields: missingFields 
            });
        }

        await db.run('BEGIN TRANSACTION');

        try {
            // Update device last seen
            await db.run(`
                UPDATE devices 
                SET last_seen_at = CURRENT_TIMESTAMP 
                WHERE device_id = ?
            `, [deviceId]);

            // Update device info
            await db.run(`
                INSERT INTO device_info (
                    device_id, battery_level, device_model, device_name,
                    os_version, screen_resolution, app_version, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(device_id) DO UPDATE SET
                    battery_level = ?,
                    device_model = ?,
                    device_name = ?,
                    os_version = ?,
                    screen_resolution = ?,
                    app_version = ?,
                    updated_at = CURRENT_TIMESTAMP
            `, [
                deviceId,
                encryptField(String(batteryLevel)),
                encryptField(deviceModel),
                encryptField(deviceName),
                encryptField(osVersion),
                encryptField(screenResolution),
                encryptField(appVersion),
                encryptField(String(batteryLevel)),
                encryptField(deviceModel),
                encryptField(deviceName),
                encryptField(osVersion),
                encryptField(screenResolution),
                encryptField(appVersion)
            ]);

            // Insert location data
            await db.run(`
                INSERT INTO device_locations (
                    id, device_id, timestamp,
                    latitude, longitude, altitude, accuracy
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            `, [
                id,
                deviceId,
                timestamp || new Date().toISOString(),
                encryptField(String(latitude)),
                encryptField(String(longitude)),
                encryptField(String(altitude)),
                encryptField(String(accuracy))
            ]);

            await db.run('COMMIT');
            res.status(200).json({ 
                success: true, 
                message: 'Device info updated successfully',
                timestamp: new Date().toISOString()
            });
        } catch (error) {
            await db.run('ROLLBACK');
            throw error;
        }
    } catch (error) {
        console.error('Error updating device info:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Device Settings Endpoint
app.get('/api/device/settings', verifyToken, async (req, res) => {
    try {
        const deviceId = req.deviceId; // From verifyToken middleware

        const settings = await db.get(`
            SELECT data_send_interval, notification_enabled, 
                   power_save_mode, last_updated
            FROM device_settings
            WHERE device_id = ?
        `, [deviceId]);

        if (!settings) {
            return res.status(404).json({ 
                message: 'Device settings not found' 
            });
        }

        res.status(200).json({
            success: true,
            settings: {
                dataSendInterval: settings.data_send_interval,
                notificationEnabled: settings.notification_enabled,
                powerSaveMode: settings.power_save_mode,
                lastUpdated: settings.last_updated
            }
        });
    } catch (error) {
        console.error('Error fetching device settings:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// WebSocket setup with enhanced authentication
io.use(async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        
        if (!token) {
            return next(new Error('Authentication error: No token provided'));
        }

        // Verify token and attach deviceId to socket
        const decoded = await verifySocketToken(token);
        socket.deviceId = decoded.deviceId;
        
        // Store authenticated state in socket
        socket.isAuthenticated = true;
        
        next();
    } catch (error) {
        next(new Error('Authentication error: Invalid token'));
    }
});

io.on('connection', (socket) => {
    console.log('Device connected:', socket.id);

    // Simplified getAllData event handler
    socket.on('getAllData', async (data, callback) => {
        try {
            // Basic validation
            if (!data.deviceId || !data.latitude || !data.longitude) {
                socket.emit('error', {
                    success: false,
                    message: 'Missing required fields'
                });
                return callback({
                    success: false,
                    message: 'Missing required fields'
                });
            }

            await db.run('BEGIN TRANSACTION');

            try {
                // Update device last seen
                await db.run(`
                    UPDATE devices 
                    SET last_seen_at = CURRENT_TIMESTAMP 
                    WHERE device_id = ?
                `, [data.deviceId]);

                // Save location data
                const locationId = uuidv4();
                await db.run(`
                    INSERT INTO device_locations (
                        id, device_id, timestamp,
                        latitude, longitude, altitude, accuracy
                    ) VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?)
                `, [
                    locationId,
                    data.deviceId,
                    encryptField(String(data.latitude)),
                    encryptField(String(data.longitude)),
                    encryptField(String(data.altitude || 0)),
                    encryptField(String(data.accuracy || 0))
                ]);

                await db.run('COMMIT');

                // Get the saved data for confirmation
                const deviceInfo = await db.get(`
                    SELECT d.device_id, d.last_seen_at,
                           dl.id as location_id, dl.timestamp,
                           dl.latitude, dl.longitude, dl.altitude, dl.accuracy
                    FROM devices d
                    LEFT JOIN device_locations dl ON dl.id = ?
                    WHERE d.device_id = ?
                `, [locationId, data.deviceId]);

                // Prepare response data
                const responseData = {
                    success: true,
                    message: 'Data saved successfully',
                    timestamp: new Date().toISOString(),
                    data: {
                        deviceId: deviceInfo.device_id,
                        lastSeenAt: deviceInfo.last_seen_at,
                        location: {
                            id: deviceInfo.location_id,
                            timestamp: deviceInfo.timestamp,
                            latitude: Number(decryptField(deviceInfo.latitude)),
                            longitude: Number(decryptField(deviceInfo.longitude)),
                            altitude: Number(decryptField(deviceInfo.altitude)),
                            accuracy: Number(decryptField(deviceInfo.accuracy))
                        }
                    }
                };

                // Send response both through callback and emit
                callback(responseData);
                socket.emit('dataReceived', responseData);

            } catch (error) {
                await db.run('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('Error saving device data:', error);
            const errorResponse = {
                success: false,
                message: 'Error saving data',
                error: error.message
            };
            callback(errorResponse);
            socket.emit('error', errorResponse);
        }
    });

    // Simplified time interval handler
    socket.on('sendTimeInterval', async (data, callback) => {
        try {
            const { deviceId } = data;
            
            // Get device settings
            const settings = await db.get(`
                SELECT data_send_interval, notification_enabled
                FROM device_settings
                WHERE device_id = ?
            `, [deviceId]);

            if (!settings) {
                return callback({
                    success: false,
                    message: 'Device settings not found'
                });
            }

            const notificationData = {
                success: true,
                message: 'Time interval retrieved successfully',
                data: {
                    interval: settings.data_send_interval,
                    enabled: settings.notification_enabled,
                    timestamp: new Date().toISOString()
                }
            };

            callback(notificationData);
            socket.emit('timeIntervalUpdated', notificationData);

        } catch (error) {
            console.error('Error sending time interval:', error);
            callback({
                success: false,
                message: 'Error retrieving time interval',
                error: error.message
            });
        }
    });

    socket.on('disconnect', () => {
        console.log('Device disconnected:', socket.id);
    });
});

// Add this new endpoint after your existing endpoints
app.post('/api/device/location-notification', verifyToken, async (req, res) => {
    try {
        const { deviceId } = req.body;

        // Validate input
        if (!deviceId) {
            return res.status(400).json({
                success: false,
                message: 'deviceId is required'
            });
        }

        try {
            // Get the latest location for the device
            const deviceLocation = await db.get(`
                SELECT latitude, longitude
                FROM device_locations
                WHERE device_id = ?
                ORDER BY timestamp DESC
                LIMIT 1
            `, [deviceId]);

            // Prepare notification payload
            const notificationPayload = {
                aps: {
                    "content-available": 1
                },
                locationEvent: {
                    latitude: deviceLocation ? Number(decryptField(deviceLocation.latitude)) : 37.7749,
                    longitude: deviceLocation ? Number(decryptField(deviceLocation.longitude)) : -122.4194,
                    message: "You are near a special location!"
                }
            };

            // Log notification
            await db.run(`
                INSERT INTO device_notifications (
                    device_id, notification_type, message
                ) VALUES (?, ?, ?)
            `, [
                deviceId,
                'location',
                JSON.stringify(notificationPayload)
            ]);

            // Send only the notification payload
            res.status(200).json(notificationPayload);

        } catch (error) {
            throw error;
        }

    } catch (error) {
        console.error('Error sending location notification:', error);
        res.status(500).json({
            success: false,
            message: 'Error sending notification',
            error: error.message
        });
    }
});

app.get('/api/device/locations/', verifyToken, async (req, res) => {
    try {
        const { deviceId } = req.query;
        const limit = req.query.limit || 50;

        // Validate deviceId
        if (!deviceId) {
            return res.status(400).json({
                success: false,
                message: 'deviceId is required'
            });
        }

        // Get location history
        const locations = await db.all(`
            SELECT id, timestamp, latitude, longitude, altitude, accuracy
            FROM device_locations
            WHERE device_id = ?
            ORDER BY timestamp DESC
            LIMIT ?
        `, [deviceId, limit]);

        // Decrypt and format locations
        const formattedLocations = locations.map(location => ({
            id: location.id,
            timestamp: location.timestamp,
            latitude: Number(decryptField(location.latitude)),
            longitude: Number(decryptField(location.longitude)),
            altitude: Number(decryptField(location.altitude)),
            accuracy: Number(decryptField(location.accuracy))
        }));

        res.status(200).json({
            success: true,
            locations: formattedLocations
        });

    } catch (error) {
        console.error('Error fetching device locations:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching device locations',
            error: error.message
        });
    }
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 