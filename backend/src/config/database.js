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
    await db.exec(`
        CREATE TABLE IF NOT EXISTS device_info (
            id TEXT PRIMARY KEY,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            latitude REAL,
            longitude REAL,
            altitude REAL,
            accuracy REAL,
            battery_level REAL,
            device_id TEXT,
            device_model TEXT,
            device_name TEXT,
            os_version TEXT,
            screen_resolution TEXT,
            app_version TEXT
        );

        CREATE TABLE IF NOT EXISTS device_settings (
            device_id TEXT PRIMARY KEY REFERENCES device_info(id),
            transmission_interval INTEGER DEFAULT 60,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS auth_tokens (
            device_id TEXT PRIMARY KEY REFERENCES device_info(id),
            token TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    `);
}

await initializeDatabase();

export default db; 