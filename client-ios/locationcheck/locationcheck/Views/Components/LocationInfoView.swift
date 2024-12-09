import SwiftUI
import CoreLocation

struct LocationInfoView: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Location")
                .font(.headline)
            Group {
                InfoRow(title: "Latitude", value: "\(location.coordinate.latitude)")
                InfoRow(title: "Longitude", value: "\(location.coordinate.longitude)")
                InfoRow(title: "Altitude", value: "\(location.altitude)m")
                InfoRow(title: "Accuracy", value:  "±\(location.horizontalAccuracy)m")
                InfoRow(title: "Updated", value: "\(location.timestamp)")
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
