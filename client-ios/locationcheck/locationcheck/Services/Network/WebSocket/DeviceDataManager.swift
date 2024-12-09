import SocketIO
import UIKit

protocol DeviceDataManagerProtocol {
    func sendDeviceDetails(_ deviceDetails: DeviceDetails) async
}

final class DeviceDataManager {
    static let shared = DeviceDataManager()
    
    private let socket: SocketIOClient
    private let manager: SocketManager
    
    var onDataReceived: ((DeviceInfoResponse) -> Void)?
    var onError: ((String) -> Void)?
    var onTimeIntervalReceived: ((TimeIntervalResponse) -> Void)?

    private init() {
        let token = KeychainService.shared.retrieve(key: "authToken") ?? ""
        
        manager = SocketManager(
            socketURL: URL(string: Constants.API.baseURL)!,
            config: [
                .log(true),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(5),
                .forceNew(true),
                .forceWebsockets(true)
            ]
        )
        socket = manager.defaultSocket
        /*
        connect()

        setupSocketListeners()
        setupTimeIntervalListener()
         */
    }
    
    func connect() {
        socket.connect()
        reconnectIfNeeded()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    private func setupSocketListeners() {
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket connected with ID:", self?.socket.sid ?? "unknown")
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            print("Socket disconnected")
        }
   
        // Data received event
        socket.on("dataReceived") { [weak self] data, _ in
            guard let responseData = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: responseData),
                  let response = try? JSONDecoder().decode(DeviceInfoResponse.self, from: jsonData) else {
                self?.onError?("Failed to parse received data")
                return
            }
            
            DispatchQueue.main.async {
                self?.onDataReceived?(response)
            }
        }
        
        // Error handling
        socket.on(clientEvent: .error) { [weak self] data, _ in
            let errorMessage = data.first.flatMap { String(describing: $0) } ?? "Unknown socket error"
            DispatchQueue.main.async {
                self?.onError?(errorMessage)
            }
        }
        
        socket.on("error") { [weak self] data, _ in
            if let errorData = data.first as? [String: Any],
               let message = errorData["message"] as? String {
                DispatchQueue.main.async {
                    self?.onError?(message)
                }
            }
        }
    }
    
    func sendDeviceDetails(_ deviceDetails: DeviceDetails) {
        guard let dict = deviceDetails.toDictionary() else {
            onError?("Failed to encode device details")
            return
        }
        
        //print("Emitting event 'getAllData' with data: \(dict)")
        
        socket.emitWithAck("testData", dict).timingOut(after: 10) { [weak self] response in
            print("DATA MANAGER RESPONSE ----- \(response)")
            
            if response.isEmpty {
                self?.onError?("No response received (No Ack)")
                return
            }
            
            guard let responseDict = response.first as? [String: Any] else {
                self?.onError?("Invalid response format")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: responseDict)
                let deviceResponse = try JSONDecoder().decode(DeviceInfoResponse.self, from: jsonData)
                
                DispatchQueue.main.async {
                    if deviceResponse.success {
                        print("Device data sent successfully")
                        self?.onDataReceived?(deviceResponse)
                    } else {
                        self?.onError?(deviceResponse.message)
                    }
                }
            } catch {
                self?.onError?("Response parsing failed: \(error.localizedDescription)")
            }
        }
    }
    
    func reconnectIfNeeded() {
        guard socket.status != .connected else { return }
        socket.connect()
    }
}

extension DeviceDataManager {
    // Setup time interval listener
    private func setupTimeIntervalListener() {
        socket.on("timeIntervalUpdated") { [weak self] data, _ in
            guard let responseData = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: responseData),
                  let response = try? JSONDecoder().decode(TimeIntervalResponse.self, from: jsonData) else {
                self?.onError?("Failed to parse time interval data")
                return
            }
            
            DispatchQueue.main.async {
                self?.onTimeIntervalReceived?(response)
            }
        }
    }
    
    // Method to request time interval
    func requestTimeInterval(deviceId: String, completion: @escaping (Result<TimeIntervalResponse, Error>) -> Void) {
        let data: [String: Any] = ["deviceId": deviceId]
        
        socket.emitWithAck("sendTimeInterval", data).timingOut(after: 5) { response in
            print("SEND TIME INTERVAL: \(response)")
            guard let responseData = response.first as? [String: Any] else {
                completion(.failure(SocketError.invalidResponse))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                let timeIntervalResponse = try JSONDecoder().decode(TimeIntervalResponse.self, from: jsonData)
                
                DispatchQueue.main.async {
                    completion(.success(timeIntervalResponse))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
