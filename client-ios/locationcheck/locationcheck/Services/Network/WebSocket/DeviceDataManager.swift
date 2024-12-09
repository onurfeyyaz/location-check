import SocketIO
import UIKit
import Foundation
import SocketIO

final class DeviceDataManager {
    static let shared = DeviceDataManager()
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    
    private var serverDataHandler: ((Bool, Double) -> Void)?
    
    private init() {
        let token = KeychainService.shared.retrieve(key: "authToken") ?? ""
        
        self.manager = SocketManager(socketURL: URL(string: Constants.API.baseURL)!,
                                     config: [
                                        .log(true),
                                        .compress,
                                        .extraHeaders(["Authorization": "Bearer \(token)"])
                                    ])
        
        self.socket = manager.defaultSocket
        connectSocket()
        setupSocketHandlers()
    }
    
    private func setupSocketHandlers() {
        socket.on(clientEvent: .connect) { _, _ in
            print("Socket connected!")
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            print("Socket disconnected!")
        }
        
        socket.on("server-location-timeinterval") { [weak self] data, _ in
            if let json = data.first as? [String: Any],
               let success = json["success"] as? Bool,
               let timeInterval = json["timeInterval"] as? Double {
                
                self?.notifyServerDataHandler(success, timeInterval)
                print("--------- GET THE TIMEEEEE \(timeInterval)")
            }
        }
    }
    
    func registerServerDataHandler(handler: @escaping (Bool, Double) -> Void) {
        serverDataHandler = handler
    }
    
    private func notifyServerDataHandler(_ success: Bool, _ timeInterval: Double) {
        serverDataHandler?(success, timeInterval)
    }
    
    func connectSocket() {
        socket.connect()
    }
    
    func disconnectSocket() {
        socket.disconnect()
    }
    
    func fetchTimeInterval() {
        socket.emit("fetch-location-timeinterval", "Request...")
    }
}
