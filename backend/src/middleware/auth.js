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

export const verifySocketToken = (socket, next) => {
    const token = socket.handshake.auth.token;

    if (!token) {
        return next(new Error('Authentication error'));
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.deviceId = decoded.deviceId;
        next();
    } catch (err) {
        next(new Error('Authentication error'));
    }
}; 