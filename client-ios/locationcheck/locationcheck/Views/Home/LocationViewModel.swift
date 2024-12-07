import Foundation
import CoreLocation

protocol LocationViewModelDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
    func didChangeAuthorizationStatus(_ isAuthorized: Bool)
}

final class LocationViewModel: ObservableObject, LocationManagerDelegate {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isAuthorized: Bool = false
    
    private let locationManager: LocationManager

    init(locationManager: LocationManager = .shared) {
        self.locationManager = locationManager
        self.isAuthorized = locationManager.isAuthorized
        self.currentLocation = locationManager.currentLocation
        self.locationManager.delegate = self
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
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func didChangeAuthorizationStatus(_ isAuthorized: Bool) {
        DispatchQueue.main.async {
            self.isAuthorized = isAuthorized
        }
    }
}
