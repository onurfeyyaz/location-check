//
//  LocationHistoryView.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import SwiftUI

struct LocationHistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundLayer
                
                VStack {
                    if viewModel.deviceDetails.isEmpty {
                        emptyStateView
                    } else {
                        locationList
                    }
                }
            }
            .navigationTitle("Location History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private var backgroundLayer: some View {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.accentColor)
                Text("Loading locations...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No Locations Saved")
                    .font(.headline)
                Text("Location data will appear here when available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var locationList: some View {
        List {
            ForEach(viewModel.deviceDetails, id: \.id) { record in
                DeviceDetailSection(record: record)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .padding(.vertical, 8)
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 10)
        .scrollContentBackground(.hidden)
        .padding(.top, -20)
    }
}

// MARK: - Device Detail Section
struct DeviceDetailSection: View {
    let record: LocationData
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            Divider()
            detailsView
        }
        .padding(.vertical, 12)
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundStyle(.blue)
            Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
        }
    }
    
    private var detailsView: some View {
        VStack(spacing: 12) {
            LocationDetailRow(
                icon: "location.north.fill",
                title: "Coordinates",
                value: String(format: "%.3f, %.3f", record.latitude, record.longitude)
            )
            
            LocationDetailRow(
                icon: "arrow.up.right",
                title: "Altitude",
                value: String(format: "%.1fm", record.altitude)
            )
            
            LocationDetailRow(
                icon: "scope",
                title: "Accuracy",
                value: String(format: "±%.1fm", record.accuracy)
            )
        }
    }
}

// MARK: - Location Detail Row
struct LocationDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
                .foregroundColor(.primary)
        }
        .font(.subheadline)
    }
}

#Preview {
    LocationHistoryView()
}
