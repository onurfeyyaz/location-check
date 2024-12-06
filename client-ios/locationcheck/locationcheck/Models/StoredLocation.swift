import CoreLocation
import SwiftData
import Foundation

@Model
class StoredLocation {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var accuracy: Double
    
    init(location: CLLocation) {
        self.id = UUID()
        self.timestamp = Date()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.accuracy = location.horizontalAccuracy
    }
}
