//
//  DeviceDetailsRequest.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

struct DeviceDetailsRequest: APIRequest {
    typealias Response = DeviceDetailsResponse
    
    private let payload: DeviceDetails
    
    init(payload: DeviceDetails) {
        self.payload = payload
    }
    
    var baseURL: URL { URL(string: Constants.API.baseURL)! }
    var path: String { Constants.API.Endpoint.info }
    var method: HTTPMethod { .POST }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var body: Data? {
        try? JSONEncoder().encode(payload)
    }
    var queryParameters: [String: String]? { nil }
}

struct DeviceDetailsResponse: Decodable {
    let success: Bool?
    let message: String?
    let timestamp: String?
}
