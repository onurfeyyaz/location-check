import CoreLocation
import SwiftData
import UIKit

@Model
class DeviceDetails: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var accuracy: Double
    var batteryLevel: Float
    var deviceId: String
    var deviceModel: String
    var deviceName: String
    var osVersion: String
    var screenResolution: String
    var appVersion: String

    init(location: CLLocation) {
        self.id = UUID()
        self.timestamp = Date()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.accuracy = location.horizontalAccuracy
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.batteryLevel = UIDevice.current.batteryLevel
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        self.deviceModel = UIDevice.current.model
        self.deviceName = UIDevice.current.name
        self.osVersion = UIDevice.current.systemVersion
        
        let screen = UIScreen.main.bounds
        self.screenResolution = "\(Int(screen.width))x\(Int(screen.height))"
        
        let infoDictionary = Bundle.main.infoDictionary
        self.appVersion = "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, latitude, longitude, altitude, accuracy, batteryLevel, deviceId, deviceModel, deviceName, osVersion, screenResolution, appVersion
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.altitude = try container.decode(Double.self, forKey: .altitude)
        self.accuracy = try container.decode(Double.self, forKey: .accuracy)
        self.batteryLevel = try container.decode(Float.self, forKey: .batteryLevel)
        self.deviceId = try container.decode(String.self, forKey: .deviceId)
        self.deviceModel = try container.decode(String.self, forKey: .deviceModel)
        self.deviceName = try container.decode(String.self, forKey: .deviceName)
        self.osVersion = try container.decode(String.self, forKey: .osVersion)
        self.screenResolution = try container.decode(String.self, forKey: .screenResolution)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(accuracy, forKey: .accuracy)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(screenResolution, forKey: .screenResolution)
        try container.encode(appVersion, forKey: .appVersion)
    }
}
