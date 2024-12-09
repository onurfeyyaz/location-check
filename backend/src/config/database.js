import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';

dotenv.config();

const __dirname = dirname(fileURLToPath(import.meta.url));
const dbPath = process.env.DB_PATH || join(__dirname, '../../data/device_data.db');

// Ensure the data directory exists
import { mkdir } from 'fs/promises';
await mkdir(dirname(dbPath), { recursive: true });

const db = await open({
    filename: dbPath,
    driver: sqlite3.Database
});

// Initialize database tables
async function initializeDatabase() {
    try {
        // First, check if the columns exist
        const tableInfo = await db.all(`PRAGMA table_info(device_settings)`);
        const existingColumns = tableInfo.map(column => column.name);

        // Create base tables
        await db.exec(`
            -- Devices table to store unique device identifiers
            CREATE TABLE IF NOT EXISTS devices (
                device_id TEXT PRIMARY KEY,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            -- Device info table to store device-specific information
            CREATE TABLE IF NOT EXISTS device_info (
                device_id TEXT PRIMARY KEY,
                battery_level TEXT,      -- Encrypted
                device_model TEXT,       -- Encrypted
                device_name TEXT,        -- Encrypted
                os_version TEXT,         -- Encrypted
                screen_resolution TEXT,  -- Encrypted
                app_version TEXT,        -- Encrypted
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (device_id) REFERENCES devices(device_id)
            );

            -- Device locations table to store location history
            CREATE TABLE IF NOT EXISTS device_locations (
                id TEXT PRIMARY KEY,
                device_id TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                latitude TEXT,           -- Encrypted
                longitude TEXT,          -- Encrypted
                altitude TEXT,           -- Encrypted
                accuracy TEXT,           -- Encrypted
                FOREIGN KEY (device_id) REFERENCES devices(device_id)
            );

            -- Device settings table
            CREATE TABLE IF NOT EXISTS device_settings (
                device_id TEXT PRIMARY KEY,
                transmission_interval INTEGER DEFAULT 60,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (device_id) REFERENCES devices(device_id)
            );

            -- Auth tokens table
            CREATE TABLE IF NOT EXISTS auth_tokens (
                device_id TEXT PRIMARY KEY,
                token TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (device_id) REFERENCES devices(device_id)
            );

            -- Device notifications table
            CREATE TABLE IF NOT EXISTS device_notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                notification_type TEXT NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (device_id) REFERENCES devices(device_id)
            );

            -- Create indexes for better query performance
            CREATE INDEX IF NOT EXISTS idx_device_locations_device_id 
            ON device_locations(device_id);
            
            CREATE INDEX IF NOT EXISTS idx_device_locations_timestamp 
            ON device_locations(timestamp);
        `);

        // Add new columns to device_settings if they don't exist
        const columnsToAdd = [
            {
                name: 'data_send_interval',
                type: 'INTEGER DEFAULT 300'
            },
            {
                name: 'notification_enabled',
                type: 'BOOLEAN DEFAULT true'
            },
            {
                name: 'power_save_mode',
                type: 'BOOLEAN DEFAULT false'
            },
            {
                name: 'last_updated',
                type: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
            }
        ];

        for (const column of columnsToAdd) {
            if (!existingColumns.includes(column.name)) {
                await db.exec(`
                    ALTER TABLE device_settings 
                    ADD COLUMN ${column.name} ${column.type}
                `);
                console.log(`Added column ${column.name} to device_settings`);
            }
        }

    } catch (error) {
        console.error('Database initialization error:', error);
        throw error;
    }
}

await initializeDatabase();

export default db; 