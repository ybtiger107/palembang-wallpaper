import CoreLocation
import Combine
import AppKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var statusMessage = "Location access is required to calculate the local solar cycle."

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
    }

    func start() { refreshAuthorizationState()
        switch authorizationStatus {
        case .notDetermined: requestAccess()
        case .authorized, .authorizedAlways: manager.startUpdatingLocation()
        case .denied: statusMessage = "Location access is disabled. Enable it in System Settings to use the solar wallpaper."
        case .restricted: statusMessage = "Location access is restricted on this Mac."
        @unknown default: statusMessage = "Location access is unavailable."
        }
    }

    func requestAccess() { manager.requestWhenInUseAuthorization() }

    func refreshLocation() {
        guard authorizationStatus == .authorized || authorizationStatus == .authorizedAlways else { start(); return }
        manager.requestLocation()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }

    private func refreshAuthorizationState() {
        authorizationStatus = manager.authorizationStatus
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        start()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        coordinate = location.coordinate
        statusMessage = ""
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard coordinate == nil else { return }
        statusMessage = "A temporary location is unavailable. Please try again shortly."
    }
}
