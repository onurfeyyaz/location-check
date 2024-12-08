# Location Check Backend Service

A secure WebSocket-based backend service for handling device information and location data.

## Features

- Secure WebSocket communication using Socket.IO
- JWT-based authentication
- Rate limiting and security middleware
- SQLite database for data storage
- Real-time device data updates
- Secure API endpoints for device information and settings

## Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher)

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```
3. Create a `.env` file in the root directory with the following variables:
```
PORT=3000
NODE_ENV=development
JWT_SECRET=your_jwt_secret_key_here
ENCRYPTION_KEY=your_encryption_key_here
DB_PATH=./data/device_data.db
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100
```

## Running the Server

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## Authentication Flow

1. First, register your device to get a JWT token:

```http
POST /api/device/register
Content-Type: application/json

{
    "deviceId": "unique-device-identifier",
    "deviceModel": "iPhone 12",
    "deviceName": "User's iPhone",
    "osVersion": "iOS 15.0"
}
```

Response:
```json
{
    "token": "your.jwt.token"
}
```

2. Verify your token (optional test endpoint):
```http
GET /api/device/verify
Authorization: Bearer your.jwt.token
```

Response:
```json
{
    "message": "Token is valid",
    "deviceId": "your-device-id"
}
```

3. Use the token for all subsequent requests and WebSocket connections.

## API Endpoints

### POST /api/device/info
Submit device information securely.

Required headers:
- Authorization: Bearer {jwt_token}

Request body:
```json
{
    "latitude": 37.7749,
    "longitude": -122.4194,
    "altitude": 0,
    "accuracy": 10,
    "batteryLevel": 0.85,
    "deviceId": "unique-device-id",
    "deviceModel": "iPhone 12",
    "deviceName": "User's iPhone",
    "osVersion": "iOS 15.0",
    "screenResolution": "2532x1170",
    "appVersion": "1.0.0"
}
```

### GET /api/device/settings
Retrieve device settings.

Required headers:
- Authorization: Bearer {jwt_token}

## WebSocket Events

### Connection
```javascript
const socket = io('http://localhost:3000', {
    auth: {
        token: 'your_jwt_token'
    }
});
```

### Events
- `getAllData`: Send device data
- `dataReceived`: Confirmation of data receipt
- `sendNotification`: Send notifications
- `notificationSent`: Confirmation of notification delivery
- `error`: Error event

## Testing the API

You can test the API using curl:

1. Register a device:
```bash
curl -X POST http://localhost:3000/api/device/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-123",
    "deviceModel": "iPhone 12",
    "deviceName": "Test iPhone",
    "osVersion": "iOS 15.0"
  }'
```

2. Verify the token:
```bash
curl -X GET http://localhost:3000/api/device/verify \
  -H "Authorization: Bearer your.jwt.token"
```

3. Send device info:
```bash
curl -X POST http://localhost:3000/api/device/info \
  -H "Authorization: Bearer your.jwt.token" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 37.7749,
    "longitude": -122.4194,
    "altitude": 0,
    "accuracy": 10,
    "batteryLevel": 0.85,
    "deviceId": "test-device-123",
    "deviceModel": "iPhone 12",
    "deviceName": "Test iPhone",
    "osVersion": "iOS 15.0",
    "screenResolution": "2532x1170",
    "appVersion": "1.0.0"
  }'
```

## Security Features

- HTTPS/WSS for secure communication
- JWT authentication for all requests
- Rate limiting to prevent abuse
- Data encryption for sensitive information
- Input validation and sanitization
- Secure database queries with parameterization

## Error Handling

The service includes comprehensive error handling for:
- Invalid authentication
- Rate limit exceeded
- Database errors
- Invalid input data
- Server errors

## License

MIT
