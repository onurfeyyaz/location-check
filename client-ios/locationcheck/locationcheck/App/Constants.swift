//
//  Constants.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

enum Constants {
    enum API {
        static let baseURL = "http://localhost:3000"
        enum Endpoint {
            static let register = "api/device/register"
            static let info = "api/device/info"
            static let notification = "/api/device/location-notification"
            static let locations = "/api/device/locations/"
        }
    }
}
