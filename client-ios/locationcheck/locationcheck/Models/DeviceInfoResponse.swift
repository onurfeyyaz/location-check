/*
 struct DeviceInfoResponse: Codable {
    let success: Bool
    let message: String?
    let deviceInfo: DeviceInfo?
    let locationHistory: [LocationHistory]?
    
    struct DeviceInfo: Codable {
        let deviceId: String
        let createdAt: String
        let lastSeenAt: String
        let batteryLevel: Float
        let deviceModel: String
        let deviceName: String
        let osVersion: String
        let screenResolution: String
        let appVersion: String
    }
    
    struct LocationHistory: Codable {
        let id: String
        let timestamp: String
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let accuracy: Double
    }
}
*/

import Foundation

// Response Models
struct DeviceInfoResponse: Codable {
    let success: Bool
    let message: String
    let timestamp: String
    let data: DeviceData
}

struct DeviceData: Codable {
    let deviceId: String
    let lastSeenAt: String
    let location: LocationData
}

struct LocationData: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let accuracy: Double
}

// Error Response Model
struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let error: String?
}

struct TimeIntervalResponse: Codable {
    let success: Bool
    let data: Int
}

enum SocketError: Error {
    case invalidResponse
    case notConnected
    case parseError
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response received from server"
        case .notConnected:
            return "Socket is not connected"
        case .parseError:
            return "Failed to parse server response"
        }
    }
}
