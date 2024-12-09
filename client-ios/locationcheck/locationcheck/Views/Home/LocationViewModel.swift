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
        
        fetchTimeInterval()
    }
    
    private func setupSocketListeners() {
        /*
        deviceDataManager.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.connectionError = error
            }
        }
         */
    }
    
    func fetchTimeInterval() {
        deviceDataManager.connectSocket()
        
        deviceDataManager.fetchTimeInterval()
        setTimeInterval()
    }
    
    func setTimeInterval() {
        var timeIntervalLocation: Double?
        deviceDataManager.registerServerDataHandler { success, time in
            timeIntervalLocation = time
        }
        locationManager.locationSaveInterval = timeIntervalLocation
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
            //self?.deviceDataManager.sendDeviceDetails(deviceDetails)
        }
    }
    
    func didChangeAuthorizationStatus(_ isAuthorized: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isAuthorized = isAuthorized
        }
    }
}

