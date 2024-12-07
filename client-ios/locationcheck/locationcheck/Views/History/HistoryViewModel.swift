//
//  HistoryViewModel.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 7.12.2024.
//

import Foundation

final class HistoryViewModel: ObservableObject {
    @Published var deviceDetails: [DeviceDetails] = []
    private let repository: LocalDBRepository
    
    init(repository: LocalDBRepository) {
        self.repository = repository
        self.deviceDetails = getDeviceDetails()
    }
    
    func getDeviceDetails() -> [DeviceDetails] {
        var devices = repository.getDeviceDetails()
        devices.sort { $0.timestamp > $1.timestamp }
        return devices
    }
    
    func reloadData() async {
        DispatchQueue.main.async {
            self.deviceDetails = self.getDeviceDetails()
        }
    }
}
