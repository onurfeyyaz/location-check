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
                if !viewModel.isAuthorized {
                    VStack {
                        Text("Location Access Required")
                            .font(.headline)
                        Text("Please enable location access to track your position")
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                        Button("Enable Location Access") {
                            viewModel.requestLocationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let location = viewModel.currentLocation {
                    LocationInfoView(location: location)
                } else {
                    VStack {
                        ProgressView("Fetching Location...")
                        Text("Please wait while we retrieve your location.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                }
            }
            .padding()
            .navigationTitle("Location Tracker")
            .onAppear {
                viewModel.startLocationUpdates()
            }
            .onChange(of: viewModel.isAuthorized) {
                if viewModel.isAuthorized {
                    viewModel.startLocationUpdates()
                }
            }
        }
    }
}
