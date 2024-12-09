import Foundation
import CoreLocation

protocol LocationViewModelDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
    func didChangeAuthorizationStatus(_ isAuthorized: Bool)
}

final class LocationViewModel: ObservableObject, LocationManagerDelegate {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var deviceInfo: DeviceInfo?
    @Published private(set) var connectionError: String?
    @Published private(set) var isLoading: Bool = false
    
    private let locationManager: LocationManager
    private let deviceDataManager: DeviceDataManager
    
    init(locationManager: LocationManager = .shared,
         deviceDataManager: DeviceDataManager = .shared) {
        self.locationManager = locationManager
        self.deviceDataManager = deviceDataManager
        
        self.isAuthorized = locationManager.isAuthorized
        self.currentLocation = locationManager.currentLocation
        self.locationManager.delegate = self
        self.deviceInfo = DeviceInfo.current()
        
        startLocationUpdates()
        setupSocketListeners()
    }
    
    private func setupSocketListeners() {
        deviceDataManager.onDataReceived = { [weak self] response in
            DispatchQueue.main.async {
                print("response message: \(response.message)")
                print("response locationData: \(response.data.location)")
                self?.connectionError = nil
            }
        }
        
        deviceDataManager.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.connectionError = error
            }
        }
    }
    
    func getTime() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        deviceDataManager.requestTimeInterval(deviceId: deviceInfo?.deviceId ?? UUID().uuidString) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        print("Time interval:", response.data.interval)
                        print("Enabled:", response.data.enabled)
                    } else {
                        self?.connectionError = response.message
                    }
                case .failure(let error):
                    self?.connectionError = error.localizedDescription
                }
            }
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    func startLocationUpdates() {
        locationManager.startLocationUpdates()
    }
}

extension LocationViewModel: LocationViewModelDelegate {
    func didUpdateLocation(_ location: CLLocation) {
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            
            let deviceDetails = DeviceDetails(location: location)
            self?.deviceDataManager.sendDeviceDetails(deviceDetails)
        }
    }
    
    func didChangeAuthorizationStatus(_ isAuthorized: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isAuthorized = isAuthorized
        }
    }
}

