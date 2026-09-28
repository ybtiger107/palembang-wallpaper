import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var statusMessage = "Location access is required to calculate the local solar cycle."

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways: manager.startUpdatingLocation()
        case .denied: statusMessage = "Location access is disabled. Enable it in System Settings to use the solar wallpaper."
        case .restricted: statusMessage = "Location access is restricted on this Mac."
        @unknown default: statusMessage = "Location access is unavailable."
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { start() }

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
