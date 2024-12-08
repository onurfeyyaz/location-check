//
//  DeviceInfoRequest.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

struct DeviceInfoRequest: APIRequest {
    private let payload: DeviceInfo
    
    init(payload: DeviceInfo) {
        self.payload = payload
    }
    
    typealias Response = DeviceInfoResponse
    
    var baseURL: URL { URL(string: Constants.API.baseURL)! }
    var path: String { Constants.API.registerEndpoint }
    var method: HTTPMethod { .POST }
    var headers: [String: String]? { ["Content-Type": "application/json"] }
    var body: Data? {
        try? JSONEncoder().encode(payload)
    }
    var queryParameters: [String: String]? { nil }
}

struct DeviceInfoResponse: Decodable {
    let token: String?
}
