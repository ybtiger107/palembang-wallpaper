import XCTest
import CoreLocation
@testable import PalembangWallpaper

final class LogicTests: XCTestCase {
    func testSolarElevationIsFinite() {
        let state = SolarEngine.state(at: Date(timeIntervalSince1970: 1_700_000_000), latitude:  -2.99, longitude: 104.76)
        XCTAssertTrue(state.elevation.isFinite)
    }

    func testSolarDirectionChangesThroughTheDay() {
        let day = Date(timeIntervalSince1970: 1_679_378_400)
        let morning = SolarEngine.state(at: day, latitude: 0, longitude: 0)
        let evening = SolarEngine.state(at: day.addingTimeInterval(12 * 60 * 60), latitude: 0, longitude: 0)
        XCTAssertEqual(morning.direction, .rising)
        XCTAssertEqual(evening.direction, .setting)
    }

    func testPaletteDaytimeIsOriginal() {
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: 20, direction: .rising)), WallpaperPalette.original.colors)
    }

    func testPaletteNighttimeIsObsidian() {
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: -8, direction: .setting)), WallpaperPalette.obsidian.colors)
    }

    func testTwilightAnchorsAndMidpoints() {
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: -3, direction: .setting)), WallpaperPalette.midnight.colors)
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: -4.5, direction: .setting))[.skyHot], "#A66A6E")
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: -4.5, direction: .rising))[.skyHot], "#84A882")
        XCTAssertEqual(PaletteEngine.palette(for: SolarState(elevation: -3, direction: .rising)), WallpaperPalette.aurora.colors)
    }

    func testInterpolationClampsAndProducesAllTokens() {
        let start = WallpaperPalette.original.colors
        let end = WallpaperPalette.obsidian.colors
        XCTAssertEqual(PaletteEngine.blend(start, end, amount: -1), start)
        XCTAssertEqual(PaletteEngine.blend(start, end, amount: 2), end)
        XCTAssertEqual(PaletteEngine.blend(start, end, amount: 0.5).count, 6)
        XCTAssertEqual(PaletteEngine.blend(start, end, amount: 0.5), PaletteEngine.blend(start, end, amount: 0.5))
    }

    func testManualLocationAcceptsCoordinateBoundaries() throws {
        XCTAssertNoThrow(try ManualLocation(latitude: -90, longitude: -180))
        XCTAssertNoThrow(try ManualLocation(latitude: 90, longitude: 180))
    }

    func testManualLocationRejectsInvalidCoordinates() {
        XCTAssertThrowsError(try ManualLocation(latitude: -90.001, longitude: 0)) { error in
            XCTAssertEqual(error as? ManualLocation.ValidationError, .invalidLatitude)
        }
        XCTAssertThrowsError(try ManualLocation(latitude: 0, longitude: 180.001)) { error in
            XCTAssertEqual(error as? ManualLocation.ValidationError, .invalidLongitude)
        }
        XCTAssertThrowsError(try ManualLocation(latitude: .infinity, longitude: 0))
    }

    func testLocationModeSelectsTheCorrectCoordinateSource() throws {
        let automatic = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let manual = try ManualLocation(latitude: 3, longitude: 4)
        XCTAssertEqual(LocationSourceResolver.coordinate(mode: .automatic, automatic: automatic, manual: manual)?.latitude, 1)
        XCTAssertEqual(LocationSourceResolver.coordinate(mode: .manual, automatic: automatic, manual: manual)?.longitude, 4)
        XCTAssertNil(LocationSourceResolver.coordinate(mode: .manual, automatic: automatic, manual: nil))
    }
}
