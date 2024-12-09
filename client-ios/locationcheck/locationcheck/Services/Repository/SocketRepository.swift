//
//  SocketRepository.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

final class SocketRepository {
    private let deviceDataManager: DeviceDataManager
    private let networkService: NetworkService
    
    init(deviceDataManager: DeviceDataManager = .shared, networkService: NetworkService = .shared) {
        self.deviceDataManager = deviceDataManager
        self.networkService = networkService
    }
}

extension SocketRepository: DeviceDataManagerProtocol {
    func sendDeviceDetails(_ deviceDetails: DeviceDetails) async {
        /// for websocket
        //deviceDataManager.sendDeviceDetails(deviceDetails)
        
        /// for http request
        do {
            let details = DeviceDetailsRequest(payload: deviceDetails)
            try await networkService.send(details)
            print("Device details sent successfully for http request.")
        } catch {
            print("Failed to send device info for http request: \(error.localizedDescription)")
        }
    }
    
    func getAllDevicesDetails() async -> [LocationData] {
        /// websocket
        //deviceDataManager.getAllDevicesDetails()
        
        /// http request
        
        let request = FetchAllLocationsRequest()
        do {
            let response = try await NetworkService.shared.send(request)
            return response.locations
        } catch {
            print("error while get all device from socket repository: \(error.localizedDescription)")
        }
        
        return []
    }
}
