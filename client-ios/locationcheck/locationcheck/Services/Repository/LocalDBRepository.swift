//
//  LocalDBRepository.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import Foundation

final class LocalDBRepository: DataSourceProtocol {
    private let dataSource: DataSource
    
    init(dataSource: DataSource = DataSource.shared) {
        self.dataSource = dataSource
    }
    
    func saveDeviceDetails(_ deviceDetails: DeviceDetails) {
        do {
            try dataSource.saveDeviceDetails(deviceDetails)
            print("Device details saved securely.")
        } catch {
            print("Failed to save device details: \(error.localizedDescription)")
        }
    }
    
    func getDeviceDetails() -> [DeviceDetails] {
        let retrievedDetails = dataSource.getDeviceDetails()
        print("Retrieved device details")
        return retrievedDetails
    }
}

