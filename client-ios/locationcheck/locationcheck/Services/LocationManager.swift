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
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
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
