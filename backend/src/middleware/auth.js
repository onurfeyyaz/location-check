import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

export const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];

    if (!token) {
        return res.status(403).json({ message: 'No token provided' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.deviceId = decoded.deviceId;
        next();
    } catch (err) {
        return res.status(401).json({ message: 'Invalid token' });
    }
};

export const generateToken = (deviceId) => {
    return jwt.sign({ deviceId }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

export const verifySocketToken = (token) => {
    return new Promise((resolve, reject) => {
        if (!token) {
            reject(new Error('No token provided'));
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            resolve(decoded);
        } catch (err) {
            reject(new Error('Invalid token'));
        }
    });
};

export const verifySocketEvent = (socket, eventName, data) => {
    return new Promise((resolve, reject) => {
        if (!socket.isAuthenticated) {
            reject(new Error('Not authenticated'));
        }
        resolve(data);
    });
}; 