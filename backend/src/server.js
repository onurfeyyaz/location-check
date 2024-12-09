import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';

import db from './config/database.js';
import { verifyToken, generateToken } from './middleware/auth.js';
import { encryptField, decryptField } from './utils/encryption.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer);

app.use((req, res, next) => {
    if (req.path === '/api/device/register') {
        return next();
    }
    verifyToken(req, res, next);
});

app.use(express.json());

/* 
* ---------------
*    WebSocket
* ---------------
*/

// WebSocket authentication
io.use(async (socket, next) => {
    const token = socket.handshake.headers.authorization?.split(' ')[1];

    if (!token) {
        return next(new Error('Authentication error: No token provided'));
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.deviceId = decoded.deviceId;
        
        socket.isAuthenticated = true;
        
        next();
    } catch (error) {
        next(new Error('Authentication error: Invalid token'));
    }
});

io.on('connection', (socket) => {
    console.log('Device connected:', socket.id);

    // send time interval for getting location
    socket.on('fetch-location-timeinterval', () => {
        const serverData = {
            success: true,
            timeInterval: 5.0
        };

        socket.emit('server-location-timeinterval', serverData);
    });

    socket.on('disconnect', () => {
        console.log('Device disconnected:', socket.id);
    });
});

/* 
* -------------------
*    HTTP Requests
* -------------------
*/

// Device Registration and Authentication
app.post('/api/device/register', async (req, res) => {
    try {
        const { deviceId, deviceModel, deviceName, osVersion, screenResolution, appVersion } = req.body;

        if (!deviceId || !deviceModel || !deviceName || !osVersion) {
            return res.status(400).json({ 
                message: 'Missing required fields', 
                required: ['deviceId', 'deviceModel', 'deviceName', 'osVersion'] 
            });
        }

        await db.run('BEGIN TRANSACTION');

        try {
            await db.run(`
                INSERT INTO devices (device_id, last_seen_at)
                VALUES (?, CURRENT_TIMESTAMP)
                ON CONFLICT(device_id) DO UPDATE SET last_seen_at = CURRENT_TIMESTAMP
            `, [deviceId]);

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

            const token = generateToken(deviceId);
            await db.run(`
                INSERT INTO auth_tokens (device_id, token)
                VALUES (?, ?)
                ON CONFLICT(device_id) DO UPDATE SET
                    token = ?,
                    created_at = CURRENT_TIMESTAMP
            `, [deviceId, token, token]);

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
            await db.run(`
                UPDATE devices 
                SET last_seen_at = CURRENT_TIMESTAMP 
                WHERE device_id = ?
            `, [deviceId]);

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
        const deviceId = req.deviceId;

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

// Notification
app.post('/api/device/location-notification', verifyToken, async (req, res) => {
    try {
        const { deviceId } = req.body;

        if (!deviceId) {
            return res.status(400).json({
                success: false,
                message: 'deviceId is required'
            });
        }

        try {
            const deviceLocation = await db.get(`
                SELECT latitude, longitude
                FROM device_locations
                WHERE device_id = ?
                ORDER BY timestamp DESC
                LIMIT 1
            `, [deviceId]);

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

            await db.run(`
                INSERT INTO device_notifications (
                    device_id, notification_type, message
                ) VALUES (?, ?, ?)
            `, [
                deviceId,
                'location',
                JSON.stringify(notificationPayload)
            ]);

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

        if (!deviceId) {
            return res.status(400).json({
                success: false,
                message: 'deviceId is required'
            });
        }

        const locations = await db.all(`
            SELECT id, timestamp, latitude, longitude, altitude, accuracy
            FROM device_locations
            WHERE device_id = ?
            ORDER BY timestamp DESC
            LIMIT ?
        `, [deviceId, limit]);

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