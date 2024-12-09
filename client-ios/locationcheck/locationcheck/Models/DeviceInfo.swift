//
//  DeviceInfo.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import UIKit

struct DeviceInfo: Codable {
    let deviceId: String
    let deviceModel: String
    let deviceName: String
    let osVersion: String
    
    static func current() -> DeviceInfo {
        return DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown",
            deviceModel: UIDevice.current.model,
            deviceName: UIDevice.current.name,
            osVersion: UIDevice.current.systemVersion
        )
    }
}
