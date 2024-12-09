import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const SALT_LENGTH = 64;
const TAG_LENGTH = 16;
const KEY_LENGTH = 32;
const ENCRYPTION_KEY = process.env.JWT_SECRET;

function getKey(salt) {
    return crypto.pbkdf2Sync(ENCRYPTION_KEY, salt, 100000, KEY_LENGTH, 'sha512');
}

export function encrypt(text) {
    const salt = crypto.randomBytes(SALT_LENGTH);
    const key = getKey(salt);
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const tag = cipher.getAuthTag();

    return {
        encrypted: encrypted,
        iv: iv.toString('hex'),
        salt: salt.toString('hex'),
        tag: tag.toString('hex')
    };
}

export function decrypt(encrypted, iv, salt, tag) {
    try {
        const key = getKey(Buffer.from(salt, 'hex'));
        const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(iv, 'hex'));
        decipher.setAuthTag(Buffer.from(tag, 'hex'));

        let decrypted = decipher.update(encrypted, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
    } catch (error) {
        console.error('Decryption error:', error);
        return null;
    }
}

export function encryptField(value) {
    if (!value) return null;
    const { encrypted, iv, salt, tag } = encrypt(value.toString());
    return JSON.stringify({ encrypted, iv, salt, tag });
}

export function decryptField(encryptedJson) {
    if (!encryptedJson) return null;
    try {
        const { encrypted, iv, salt, tag } = JSON.parse(encryptedJson);
        return decrypt(encrypted, iv, salt, tag);
    } catch (error) {
        console.error('Field decryption error:', error);
        return null;
    }
} 