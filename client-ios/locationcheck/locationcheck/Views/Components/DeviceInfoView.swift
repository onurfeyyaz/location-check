import SwiftUI

struct DeviceInfoView: View {
    let deviceInfo: DeviceInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device Information")
                .font(.headline)
                .padding(.bottom, 5)
            
            Group {
                InfoRow(title: "Device Name", value: deviceInfo.deviceName)
                InfoRow(title: "Model", value: deviceInfo.deviceModel)
                InfoRow(title: "OS Version", value: deviceInfo.osVersion)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
} 
