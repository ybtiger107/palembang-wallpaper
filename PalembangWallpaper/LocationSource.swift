import CoreLocation

enum LocationMode: String, CaseIterable, Identifiable {
    case automatic
    case manual

    var id: String { rawValue }
    var title: String { self == .automatic ? "Automatic Location" : "Manual Location" }
}

struct ManualLocation: Equatable {
    enum ValidationError: LocalizedError, Equatable {
        case invalidLatitude
        case invalidLongitude

        var errorDescription: String? {
            switch self {
            case .invalidLatitude: return "Latitude must be a finite number from -90 to 90."
            case .invalidLongitude: return "Longitude must be a finite number from -180 to 180."
            }
        }
    }

    let country: String
    let city: String
    let latitude: Double
    let longitude: Double

    init(country: String = "", city: String = "", latitude: Double, longitude: Double) throws {
        guard latitude.isFinite, (-90...90).contains(latitude) else { throw ValidationError.invalidLatitude }
        guard longitude.isFinite, (-180...180).contains(longitude) else { throw ValidationError.invalidLongitude }
        self.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

enum LocationSourceResolver {
    static func coordinate(mode: LocationMode, automatic: CLLocationCoordinate2D?, manual: ManualLocation?) -> CLLocationCoordinate2D? {
        mode == .automatic ? automatic : manual?.coordinate
    }
}
