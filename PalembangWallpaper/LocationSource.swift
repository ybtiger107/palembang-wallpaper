import CoreLocation

enum LocationMode: String, CaseIterable, Identifiable {
    case automatic, city, custom
    var id: String { rawValue }
    var title: String { switch self { case .automatic: "Automatic"; case .city: "City"; case .custom: "Custom Coordinates" } }
}

struct CityLocation: Identifiable, Equatable {
    let countryCode: String; let countryName: String; let cityName: String; let latitude: Double; let longitude: Double
    var id: String { "\(countryCode)-\(cityName)" }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var displayName: String { "\(cityName), \(countryName)" }
}

enum CityCatalog {
    static let all: [CityLocation] = [
        ("KR", "South Korea", "Seoul", 37.5665, 126.9780), ("KR", "South Korea", "Suwon", 37.2636, 127.0286), ("KR", "South Korea", "Incheon", 37.4563, 126.7052), ("KR", "South Korea", "Busan", 35.1796, 129.0756), ("KR", "South Korea", "Daegu", 35.8714, 128.6014), ("KR", "South Korea", "Daejeon", 36.3504, 127.3845), ("KR", "South Korea", "Gwangju", 35.1595, 126.8526), ("KR", "South Korea", "Ulsan", 35.5384, 129.3114), ("KR", "South Korea", "Sejong", 36.4800, 127.2890), ("KR", "South Korea", "Jeju", 33.4996, 126.5312),
        ("JP", "Japan", "Tokyo", 35.6762, 139.6503), ("JP", "Japan", "Osaka", 34.6937, 135.5023), ("SG", "Singapore", "Singapore", 1.3521, 103.8198), ("HK", "Hong Kong", "Hong Kong", 22.3193, 114.1694), ("GB", "United Kingdom", "London", 51.5074, -0.1278), ("FR", "France", "Paris", 48.8566, 2.3522), ("DE", "Germany", "Berlin", 52.5200, 13.4050), ("US", "United States", "New York", 40.7128, -74.0060), ("US", "United States", "Los Angeles", 34.0522, -118.2437), ("US", "United States", "San Francisco", 37.7749, -122.4194), ("CA", "Canada", "Toronto", 43.6532, -79.3832), ("AU", "Australia", "Sydney", -33.8688, 151.2093)
    ].map { CityLocation(countryCode: $0.0, countryName: $0.1, cityName: $0.2, latitude: $0.3, longitude: $0.4) }
    static var countries: [String] { Array(Set(all.map(\.countryName))).sorted() }
    static func cities(in country: String) -> [CityLocation] { all.filter { $0.countryName == country }.sorted { $0.cityName < $1.cityName } }
    static func find(country: String, city: String) -> CityLocation? { all.first { $0.countryName == country && $0.cityName == city } }
}

struct CustomLocation: Equatable {
    enum ValidationError: LocalizedError, Equatable { case invalidLatitude, invalidLongitude; var errorDescription: String? { self == .invalidLatitude ? "Latitude must be a finite number from -90 to 90." : "Longitude must be a finite number from -180 to 180." } }
    let label: String; let latitude: Double; let longitude: Double
    init(label: String = "", latitude: Double, longitude: Double) throws { guard latitude.isFinite, (-90...90).contains(latitude) else { throw ValidationError.invalidLatitude }; guard longitude.isFinite, (-180...180).contains(longitude) else { throw ValidationError.invalidLongitude }; self.label = label.trimmingCharacters(in: .whitespacesAndNewlines); self.latitude = latitude; self.longitude = longitude }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

enum LocationSourceResolver {
    static func coordinate(mode: LocationMode, automatic: CLLocationCoordinate2D?, city: CityLocation?, custom: CustomLocation?) -> CLLocationCoordinate2D? { switch mode { case .automatic: automatic; case .city: city?.coordinate; case .custom: custom?.coordinate } }
    static func displayLabel(mode: LocationMode, automatic: CLLocationCoordinate2D?, city: CityLocation?, custom: CustomLocation?) -> String? { switch mode { case .automatic: automatic.map { String(format: "%.4f°, %.4f°", $0.latitude, $0.longitude) }; case .city: city?.displayName; case .custom: custom?.label.isEmpty == false ? custom?.label : custom.map { String(format: "%.4f°, %.4f°", $0.latitude, $0.longitude) } } }
}
