import Foundation
import CoreLocation
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var userLocation: CLLocation?
    @Published var isWithinCampusRadius: Bool? = nil
    @Published var locationError: String?
    @Published var permissionStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()

    // Fixed location: your campus center for comparison (not user location)
    private let campusCenter = CLLocation(latitude: 38.0336, longitude: -78.5080) // Example: UVA

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        permissionStatus = CLLocationManager.authorizationStatus()
        print("[LocationManager] Initialized. Permission status:", permissionStatus.rawValue)
        // Do NOT call requestLocation() here! Only trigger in response to user action.
    }

    /// Call this method (from a button, e.g. "Looks Good") to ask for permission and update location
    func requestLocation() {
        let status = CLLocationManager.authorizationStatus()
        print("[LocationManager] requestLocation() called. Current status:", status.rawValue)
        if status == .notDetermined {
            print("[LocationManager] Status not determined. Requesting WhenInUse authorization.")
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("[LocationManager] Already authorized. Starting location updates.")
            locationManager.startUpdatingLocation()
        } else {
            print("[LocationManager] Denied or restricted.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationManager] didUpdateLocations called with \(locations.count) locations.")
        guard let location = locations.first else {
            print("[LocationManager] No valid locations found.")
            return
        }
        print("[LocationManager] Got user location:", location.coordinate.latitude, location.coordinate.longitude)
        userLocation = location

        // Development only: allow access everywhere!
        isWithinCampusRadius = true


        // Stop updating to save battery
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Location error:", error.localizedDescription)
        locationError = error.localizedDescription
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
        print("[LocationManager] Authorization status changed to:", permissionStatus.rawValue)
        // Optionally, auto-request a location if now authorized:
        if permissionStatus == .authorizedWhenInUse || permissionStatus == .authorizedAlways {
            print("[LocationManager] Now authorized, starting location updates.")
            locationManager.startUpdatingLocation()
        }
    }
}

