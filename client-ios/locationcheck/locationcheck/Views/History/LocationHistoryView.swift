//
//  LocationHistoryView.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import SwiftUI

struct LocationHistoryView: View {
    @StateObject private var viewModel = HistoryViewModel(repository: LocalDBRepository())
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.deviceDetails.isEmpty {
                    Text("No saved location here...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                } else {
                    List(viewModel.deviceDetails) { record in
                        DeviceDetailSection(record: record)
                    }
                    .padding(.top, 10)
                }
            }
            .refreshable {
                await viewModel.reloadData()
            }
        }
    }
}
// MARK: - Device Detail Section

struct DeviceDetailSection: View {
    let record: DeviceDetails
    
    var body: some View {
        Section(header: deviceDetailHeader) {
            VStack(alignment: .leading, spacing: 16) {
                DeviceDetailRow(title: "Latitude", value: "\(record.latitude)")
                DeviceDetailRow(title: "Longitude", value: "\(record.longitude)")
                DeviceDetailRow(title: "Altitude", value: "\(record.altitude)m")
                DeviceDetailRow(title: "Accuracy", value: "\(record.accuracy)m")
                
                Divider()
                
                DeviceDetailRow(title: "Battery Level", value: "\(record.batteryLevel * 100)%")
                DeviceDetailRow(title: "Device ID", value: record.deviceId)
                DeviceDetailRow(title: "Device Model", value: record.deviceModel)
                DeviceDetailRow(title: "Device Name", value: record.deviceName)
                DeviceDetailRow(title: "OS Version", value: record.osVersion)
                DeviceDetailRow(title: "Screen Resolution", value: record.screenResolution)
                DeviceDetailRow(title: "App Version", value: record.appVersion)
            }
            .font(.body)
            .foregroundColor(.primary)
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
    }
    
    private var deviceDetailHeader: some View {
        Text("\(record.timestamp, style: .date) \(record.timestamp, style: .time)")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 10)
            .padding(.horizontal, 15)
    }
}
// MARK: - Device Detail Row

struct DeviceDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 5)
    }
}

extension LocationHistoryView {
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
