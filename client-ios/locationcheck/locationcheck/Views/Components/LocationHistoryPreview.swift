import SwiftUI
import CoreLocation

struct LocationHistoryPreview: View {
    let history: [LocationData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Locations")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(history.prefix(3), id: \.id) { location in
                LocationHistoryRow(location: location)
            }
            
            if history.count > 3 {
                NavigationLink(destination: LocationHistoryView()) {
                    Text("View All (\(history.count) locations)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

private struct LocationHistoryRow: View {
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(formatDate("\(location.timestamp)"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Lat: \(location.latitude, specifier: "%.4f")")
                Text("Long: \(location.longitude, specifier: "%.4f")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
