import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

import db from './config/database.js';
import { verifyToken, verifySocketToken, generateToken } from './middleware/auth.js';

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
        const { deviceId, deviceModel, deviceName, osVersion } = req.body;

        // Validate required fields
        if (!deviceId || !deviceModel || !deviceName || !osVersion) {
            return res.status(400).json({ 
                message: 'Missing required fields', 
                required: ['deviceId', 'deviceModel', 'deviceName', 'osVersion'] 
            });
        }

        // Check if device already exists
        const existingDevice = await db.get(
            'SELECT device_id FROM device_info WHERE device_id = ?',
            [deviceId]
        );

        if (existingDevice) {
            // If device exists, generate new token
            const token = generateToken(deviceId);
            await db.run(
                'INSERT OR REPLACE INTO auth_tokens (device_id, token) VALUES (?, ?)',
                [deviceId, token]
            );
            return res.json({ token });
        }

        // Create new device entry
        const id = uuidv4();
        await db.run(`
            INSERT INTO device_info (
                id, device_id, device_model, device_name, os_version
            ) VALUES (?, ?, ?, ?, ?)
        `, [id, deviceId, deviceModel, deviceName, osVersion]);

        // Generate and store token
        const token = generateToken(deviceId);
        await db.run(
            'INSERT INTO auth_tokens (device_id, token) VALUES (?, ?)',
            [deviceId, token]
        );

        // Create default device settings
        await db.run(
            'INSERT INTO device_settings (device_id) VALUES (?)',
            [deviceId]
        );

        res.status(201).json({ token });
    } catch (error) {
        console.error('Error registering device:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Test endpoint to verify JWT
app.get('/api/device/verify', verifyToken, (req, res) => {
    res.json({ 
        message: 'Token is valid',
        deviceId: req.deviceId
    });
});

// API Routes
app.post('/api/device/info', verifyToken, async (req, res) => {
    try {
        const deviceInfo = {
            id: uuidv4(),
            ...req.body,
            timestamp: new Date().toISOString()
        };

        await db.run(`
            INSERT INTO device_info (
                id, timestamp, latitude, longitude, altitude, accuracy,
                battery_level, device_id, device_model, device_name,
                os_version, screen_resolution, app_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
            deviceInfo.id, deviceInfo.timestamp, deviceInfo.latitude,
            deviceInfo.longitude, deviceInfo.altitude, deviceInfo.accuracy,
            deviceInfo.batteryLevel, deviceInfo.deviceId, deviceInfo.deviceModel,
            deviceInfo.deviceName, deviceInfo.osVersion, deviceInfo.screenResolution,
            deviceInfo.appVersion
        ]);

        res.status(201).json({ message: 'Device info saved successfully' });
    } catch (error) {
        console.error('Error saving device info:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

app.get('/api/device/settings', verifyToken, async (req, res) => {
    try {
        const settings = await db.get(
            'SELECT transmission_interval FROM device_settings WHERE device_id = ?',
            [req.deviceId]
        );

        res.json(settings || { transmission_interval: 60 });
    } catch (error) {
        console.error('Error fetching device settings:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// WebSocket setup
io.use(verifySocketToken);

io.on('connection', (socket) => {
    console.log('Device connected:', socket.deviceId);

    socket.on('getAllData', async (data) => {
        try {
            // Validate and save the received data
            const deviceInfo = {
                id: uuidv4(),
                ...data,
                timestamp: new Date().toISOString()
            };

            await db.run(`
                INSERT INTO device_info (
                    id, timestamp, latitude, longitude, altitude, accuracy,
                    battery_level, device_id, device_model, device_name,
                    os_version, screen_resolution, app_version
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                deviceInfo.id, deviceInfo.timestamp, deviceInfo.latitude,
                deviceInfo.longitude, deviceInfo.altitude, deviceInfo.accuracy,
                deviceInfo.batteryLevel, deviceInfo.deviceId, deviceInfo.deviceModel,
                deviceInfo.deviceName, deviceInfo.osVersion, deviceInfo.screenResolution,
                deviceInfo.appVersion
            ]);

            socket.emit('dataReceived', { success: true });
        } catch (error) {
            console.error('Error processing device data:', error);
            socket.emit('error', { message: 'Error processing data' });
        }
    });

    socket.on('sendNotification', async (data) => {
        try {
            // Here you would implement your notification logic
            // For example, sending push notifications or storing them in the database
            socket.emit('notificationSent', { success: true });
        } catch (error) {
            console.error('Error sending notification:', error);
            socket.emit('error', { message: 'Error sending notification' });
        }
    });

    socket.on('disconnect', () => {
        console.log('Device disconnected:', socket.deviceId);
    });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 