import SwiftUI
import CoreLocation

struct LocationInfoView: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Location")
                .font(.headline)
            
            Group {
                Text("Latitude: \(location.coordinate.latitude, specifier: "%.4f")")
                Text("Longitude: \(location.coordinate.longitude, specifier: "%.4f")")
                Text("Altitude: \(location.altitude, specifier: "%.1f")m")
                Text("Accuracy: ±\(location.horizontalAccuracy, specifier: "%.1f")m")
                Text("Updated: \(location.timestamp, style: .time)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
