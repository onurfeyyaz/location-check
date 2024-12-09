//
//  NotificationPayload.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 9.12.2024.
//

import Foundation

struct NotificationPayload: Codable {
    let aps: APS
    let locationEvent: LocationEvent
}

struct APS: Codable {
    let contentAvailable: Int
    
    enum CodingKeys: String, CodingKey {
        case contentAvailable = "content-available"
    }
}

struct LocationEvent: Codable {
    let latitude: Double
    let longitude: Double
    let message: String
}
