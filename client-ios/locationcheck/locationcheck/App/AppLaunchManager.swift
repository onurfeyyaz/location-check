//
//  AppLaunchManager.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 8.12.2024.
//


import Foundation

// MARK: - App Launch Handling
final class AppLaunchManager {
    
    static func handleAppLaunch() async {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore || KeychainService.shared.retrieve(key: "authToken") == nil {
            await sendDeviceInfoIfNeeded()
            
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        else {
            print("Launched before or there is a token!")
        }
    }
    
    private static func sendDeviceInfoIfNeeded() async {
        do {
            let request = DeviceInfoRequest(payload: DeviceInfo.current())
            let token = try await NetworkService.shared.send(request).token!
            KeychainService.shared.save(key: "authToken", value: token)
            print("Device info sent successfully.")
        } catch {
            print("Failed to send device info: \(error.localizedDescription)")
        }
    }
}
