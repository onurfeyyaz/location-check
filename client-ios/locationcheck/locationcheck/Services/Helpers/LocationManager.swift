import Foundation
import CoreLocation

protocol LocationManagerDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
    func didChangeAuthorizationStatus(_ isAuthorized: Bool)
}

final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    weak var delegate: LocationManagerDelegate?
    
    private let locationManager = CLLocationManager()
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isAuthorized: Bool = false
    
    private var locationSaveTimer: Timer?
    var locationSaveInterval: TimeInterval?
    
    private var localDBRepository = LocalDBRepository()
    private var socketRepository = SocketRepository()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .other
    }
    
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Location access already granted for Always.")
        case .denied, .restricted:
            print("Location access denied or restricted. Enable it in Settings.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        
        startLocationSaveTimer()
    }
    
    private func startLocationSaveTimer() {
        locationSaveTimer?.invalidate()
        
        locationSaveTimer = Timer.scheduledTimer(withTimeInterval: locationSaveInterval ?? 40, repeats: true) { [weak self] _ in
            guard let self = self, let currentLocation = self.currentLocation else { return }
            
            let deviceDetails = DeviceDetails(location: currentLocation)
            
            self.localDBRepository.saveDeviceDetails(deviceDetails)
            
            Task {
                await self.socketRepository.sendDeviceDetails(deviceDetails)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.delegate?.didUpdateLocation(location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        DispatchQueue.main.async {
            self.isAuthorized = isAuthorized
            self.delegate?.didChangeAuthorizationStatus(isAuthorized)
        }
        
        if status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
}
