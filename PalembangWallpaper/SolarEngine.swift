import Foundation

struct SolarState: Equatable {
    enum Direction: Equatable { case rising, setting, stationary }
    let elevation: Double
    let direction: Direction
}

enum SolarEngine {
    static func state(at date: Date, latitude: Double, longitude: Double) -> SolarState {
        let elevation = solarElevation(at: date, latitude: latitude, longitude: longitude)
        let before = solarElevation(at: date.addingTimeInterval(-60), latitude: latitude, longitude: longitude)
        let after = solarElevation(at: date.addingTimeInterval(60), latitude: latitude, longitude: longitude)
        let change = after - before
        let direction: SolarState.Direction = change > 0.0001 ? .rising : change < -0.0001 ? .setting : .stationary
        return SolarState(elevation: elevation, direction: direction)
    }

    static func solarElevation(at date: Date, latitude: Double, longitude: Double) -> Double {
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let centuries = (julianDay - 2_451_545.0) / 36_525.0
        let meanLongitude = normalizedDegrees(280.46646 + centuries * (36_000.76983 + centuries * 0.0003032))
        let meanAnomaly = normalizedDegrees(357.52911 + centuries * (35_999.05029 - 0.0001537 * centuries))
        let anomalyRadians = meanAnomaly * .pi / 180
        let equationOfCenter = sin(anomalyRadians) * (1.914602 - centuries * (0.004817 + 0.000014 * centuries))
            + sin(2 * anomalyRadians) * (0.019993 - 0.000101 * centuries) + sin(3 * anomalyRadians) * 0.000289
        let apparentLongitude = meanLongitude + equationOfCenter - 0.00569 - 0.00478 * sin((125.04 - 1934.136 * centuries) * .pi / 180)
        let obliquity = 23.439291 - 0.0130042 * centuries
        let longitudeRadians = apparentLongitude * .pi / 180
        let obliquityRadians = obliquity * .pi / 180
        let declination = asin(sin(obliquityRadians) * sin(longitudeRadians))
        let rightAscension = atan2(cos(obliquityRadians) * sin(longitudeRadians), cos(longitudeRadians))
        let siderealTime = normalizedDegrees(280.46061837 + 360.98564736629 * (julianDay - 2_451_545.0)
            + 0.000387933 * centuries * centuries - centuries * centuries * centuries / 38_710_000)
        let hourAngle = signedDegrees(siderealTime + longitude - rightAscension * 180 / .pi) * .pi / 180
        let latitudeRadians = latitude * .pi / 180
        let elevation = asin(sin(latitudeRadians) * sin(declination) + cos(latitudeRadians) * cos(declination) * cos(hourAngle)) * 180 / .pi
        return elevation.isFinite ? elevation : 0
    }

    private static func normalizedDegrees(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder >= 0 ? remainder : remainder + 360
    }

    private static func signedDegrees(_ degrees: Double) -> Double {
        let normalized = normalizedDegrees(degrees)
        return normalized > 180 ? normalized - 360 : normalized
    }
}
