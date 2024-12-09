//
//  APIRequest.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

// MARK: - Endpoint Protocol
protocol APIRequest {
    associatedtype Response: Decodable
    
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET, POST
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case decodingError(Error)
    case serverError(Int)
    case networkFailure(Error)
}
