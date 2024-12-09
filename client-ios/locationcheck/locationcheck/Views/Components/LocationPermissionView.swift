import SwiftUI

struct LocationPermissionView: View {
    let viewModel: LocationViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom)
            
            Text("Location Access Required")
                .font(.headline)
            
            Text("Please enable location access to track your position")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            Button("Enable Location Access") {
                viewModel.requestLocationPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding()
    }
} 
