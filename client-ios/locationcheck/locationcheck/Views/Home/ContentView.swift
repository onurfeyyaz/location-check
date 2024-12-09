//
//  ContentView.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = LocationViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    if let error = viewModel.connectionError {
                        ConnectionErrorView(message: error)
                    }
                    
                    if !viewModel.isAuthorized {
                        LocationPermissionView(viewModel: viewModel)
                            .padding(.top, 30)
                    } else {
                        VStack(spacing: 20) {
                            if let deviceInfo = viewModel.deviceInfo {
                                DeviceInfoView(deviceInfo: deviceInfo)
                            }
                            if let location = viewModel.currentLocation {
                                LocationInfoView(location: location)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Location Tracker")
                .onAppear {
                    if viewModel.isAuthorized {
                        viewModel.startLocationUpdates()
                    }
                }
            }
        }
    }
}

struct ConnectionErrorView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
    }
}
