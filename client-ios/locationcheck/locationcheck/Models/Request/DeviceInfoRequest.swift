//
//  DeviceInfoRequest.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

struct DeviceInfoRequest: APIRequest {
    typealias Response = DeviceTokenResponse
    
    private let payload: DeviceInfo
    
    init(payload: DeviceInfo) {
        self.payload = payload
    }
    
    var baseURL: URL { URL(string: Constants.API.baseURL)! }
    var path: String { Constants.API.Endpoint.register }
    var method: HTTPMethod { .POST }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var body: Data? {
        try? JSONEncoder().encode(payload)
    }
    var queryParameters: [String: String]? { nil }
}

struct DeviceTokenResponse: Decodable {
    let token: String?
}
