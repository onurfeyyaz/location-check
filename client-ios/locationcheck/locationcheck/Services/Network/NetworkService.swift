//
//  NetworkService.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//

import Foundation

// MARK: - Network Service
final class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    func send<T: APIRequest>(_ request: T) async throws -> T.Response {
        let token = KeychainService.shared.retrieve(key: "authToken")
        
        guard var urlComponents = URLComponents(
            url: request.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        
        if let queryParameters = request.queryParameters {
            urlComponents.queryItems = queryParameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        
        if let token {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlRequest.httpBody = request.body
        
        print("Sending request to \(urlRequest.url?.absoluteString ?? "")")
        print("Headers: \(urlRequest.allHTTPHeaderFields?.filter { $0.key != "Authorization" } ?? [:])")
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server responded with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
                return decodedResponse
            } catch {
                print("Decoding error: \(error)")
                print("Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw NetworkError.decodingError(error)
            }
        } catch {
            print("Network error: \(error.localizedDescription)")
            throw NetworkError.networkFailure(error)
        }
    }
}
