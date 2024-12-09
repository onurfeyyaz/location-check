//
//  FetchAllLocationsRequest.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

struct FetchAllLocationsRequest: APIRequest {
    typealias Response = LocationResponse
    
    var baseURL: URL { URL(string: Constants.API.baseURL)! }
    var path: String { Constants.API.Endpoint.locations }
    var method: HTTPMethod { .GET }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var body: Data? { nil }
    var queryParameters: [String: String]? {
        ["deviceId": "\(DeviceInfo.current().deviceId)"]
    }
}

struct LocationResponse: Codable {
    let success: Bool
    let locations: [LocationData]
}
