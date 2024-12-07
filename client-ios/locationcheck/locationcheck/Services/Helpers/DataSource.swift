//
//  DataSource.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import SwiftData
import Foundation

protocol DataSourceProtocol {
    func saveDeviceDetails(_ deviceDetails: DeviceDetails) throws
    func getDeviceDetails() -> [DeviceDetails]
}

final class DataSource: DataSourceProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    @MainActor
    static let shared = DataSource()
    
    @MainActor
    init() {
        self.modelContainer = try! ModelContainer(for: DeviceDetails.self)
        self.modelContext = modelContainer.mainContext
    }

    func saveDeviceDetails(_ deviceDetails: DeviceDetails) throws {
        modelContext.insert(deviceDetails)
        
        do {
            try modelContext.save()
        } catch {
            fatalError("DataSource Save Error: \(error.localizedDescription)")
        }
    }

    func getDeviceDetails() -> [DeviceDetails] {
        do {
            return try modelContext.fetch(FetchDescriptor<DeviceDetails>())
        } catch {
            print("DataSource Get Device Error: \(error.localizedDescription)")
            return []
        }
    }
}
