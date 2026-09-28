import SwiftUI
import Foundation
import Combine
import CoreLocation
import PalembangKit
import PalembangSwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: WallpaperModel
    var body: some View {
        Group {
            if let palette = model.palette { PalembangView(palette: palette).ignoresSafeArea().animation(.easeInOut(duration: 1.5), value: palette) }
            else { VStack(spacing: 12) { Image(systemName: "location.slash").font(.title); Text("Location is needed to calculate your local solar cycle.").multilineTextAlignment(.center); HStack { if model.canRequestLocation { Button("Use Current Location") { model.requestAutomaticLocation() } }; Button("Choose a City…") { model.selectMode(.city) } }; Button("Custom Location…") { model.selectMode(.custom) }.buttonStyle(.link) }.frame(maxWidth: .infinity, maxHeight: .infinity).background(.black).foregroundStyle(.white) }
        }.onAppear { model.start() }.onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { model.refresh(at: $0) }
    }
}

@MainActor final class WallpaperModel: ObservableObject {
    @Published private(set) var palette: [PalembangPaletteToken: String]?
    @Published private(set) var statusMessage = "Location is needed to calculate your local solar cycle."
    @Published private(set) var locationMode: LocationMode
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var automaticCoordinate: CLLocationCoordinate2D?
    @Published private(set) var validationMessage: String?
    @Published private(set) var selectedCountry: String; @Published private(set) var selectedCity: String
    @Published private(set) var customLabel: String; @Published private(set) var customLatitude: String; @Published private(set) var customLongitude: String
    private let locationService = LocationService(); private let defaults = UserDefaults.standard; private var hasStarted = false
    private enum Keys { static let mode = "location.mode"; static let country = "location.city.country"; static let city = "location.city.name"; static let label = "location.custom.label"; static let latitude = "location.custom.latitude"; static let longitude = "location.custom.longitude" }
    init() { locationMode = LocationMode(rawValue: defaults.string(forKey: Keys.mode) ?? "") ?? .automatic; selectedCountry = defaults.string(forKey: Keys.country) ?? "South Korea"; selectedCity = defaults.string(forKey: Keys.city) ?? "Seoul"; customLabel = defaults.string(forKey: Keys.label) ?? ""; customLatitude = defaults.string(forKey: Keys.latitude) ?? ""; customLongitude = defaults.string(forKey: Keys.longitude) ?? "" }
    func start() { guard !hasStarted else { return }; hasStarted = true; locationService.start(); syncLocationState(); refresh(at: Date()) }
    var canRequestLocation: Bool { authorizationStatus == .notDetermined }; var isLocationDenied: Bool { authorizationStatus == .denied || authorizationStatus == .restricted }
    var selectedCityLocation: CityLocation? { CityCatalog.find(country: selectedCountry, city: selectedCity) }; var filteredCities: [CityLocation] { CityCatalog.cities(in: selectedCountry) }
    var resolvedLabel: String? { LocationSourceResolver.displayLabel(mode: locationMode, automatic: automaticCoordinate, city: selectedCityLocation, custom: customLocation) }
    private var customLocation: CustomLocation? { try? CustomLocation(label: customLabel, latitude: Double(customLatitude) ?? .nan, longitude: Double(customLongitude) ?? .nan) }
    func selectMode(_ mode: LocationMode) { locationMode = mode; defaults.set(mode.rawValue, forKey: Keys.mode); if mode == .automatic { locationService.start() }; refresh(at: Date()) }
    func selectCountry(_ country: String) { selectedCountry = country; defaults.set(country, forKey: Keys.country); if selectedCityLocation == nil { selectedCity = CityCatalog.cities(in: country).first?.cityName ?? ""; defaults.set(selectedCity, forKey: Keys.city) }; refresh(at: Date()) }
    func selectCity(_ city: String) { selectedCity = city; defaults.set(city, forKey: Keys.city); refresh(at: Date()) }
    func requestAutomaticLocation() { selectMode(.automatic); locationService.requestAccess(); locationService.refreshLocation(); syncLocationState() }
    func refreshAutomaticLocation() { locationService.refreshLocation(); syncLocationState(); refresh(at: Date()) }
    func openSystemSettings() { locationService.openSystemSettings() }
    func saveCustom(label: String, latitude: String, longitude: String) -> Bool { do { let location = try CustomLocation(label: label, latitude: Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .nan, longitude: Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .nan); customLabel = location.label; customLatitude = String(location.latitude); customLongitude = String(location.longitude); defaults.set(customLabel, forKey: Keys.label); defaults.set(customLatitude, forKey: Keys.latitude); defaults.set(customLongitude, forKey: Keys.longitude); validationMessage = nil; selectMode(.custom); return true } catch let error as CustomLocation.ValidationError { validationMessage = error.localizedDescription; return false } catch { validationMessage = "Latitude and longitude must be valid numbers."; return false } }
    func refresh(at date: Date) { syncLocationState(); guard let coordinate = LocationSourceResolver.coordinate(mode: locationMode, automatic: automaticCoordinate, city: selectedCityLocation, custom: customLocation) else { statusMessage = locationMode == .city ? "Choose a valid city." : locationMode == .custom ? "Set valid custom coordinates." : locationService.statusMessage; palette = nil; return }; palette = PaletteEngine.palette(for: SolarEngine.state(at: date, latitude: coordinate.latitude, longitude: coordinate.longitude)); statusMessage = "" }
    private func syncLocationState() { authorizationStatus = locationService.authorizationStatus; automaticCoordinate = locationService.coordinate }
}

struct LocationSettingsView: View {
    @EnvironmentObject private var model: WallpaperModel
    @State private var label = ""; @State private var latitude = ""; @State private var longitude = ""
    var body: some View { Form { Picker("Location", selection: Binding(get: { model.locationMode }, set: { model.selectMode($0) })) { ForEach(LocationMode.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented); switch model.locationMode { case .automatic: automaticControls; case .city: cityControls; case .custom: customControls } }.padding().frame(width: 390).onAppear { label = model.customLabel; latitude = model.customLatitude; longitude = model.customLongitude } }
    @ViewBuilder private var automaticControls: some View { Text(model.authorizationStatus.label).foregroundStyle(.secondary); if let label = model.resolvedLabel { Text(label).font(.caption) }; HStack { if model.canRequestLocation { Button("Request Permission") { model.requestAutomaticLocation() } }; if model.isLocationDenied { Button("Open System Settings") { model.openSystemSettings() } }; Button("Refresh") { model.refreshAutomaticLocation() } } }
    @ViewBuilder private var cityControls: some View { Picker("Country", selection: Binding(get: { model.selectedCountry }, set: { model.selectCountry($0) })) { ForEach(CityCatalog.countries, id: \.self) { Text($0).tag($0) } }; Picker("City", selection: Binding(get: { model.selectedCity }, set: { model.selectCity($0) })) { ForEach(model.filteredCities) { Text($0.cityName).tag($0.cityName) } }; if let label = model.resolvedLabel { Text(label).font(.caption).foregroundStyle(.secondary) } }
    @ViewBuilder private var customControls: some View { TextField("Label (optional)", text: $label); TextField("Latitude", text: $latitude); TextField("Longitude", text: $longitude); if let message = model.validationMessage { Text(message).foregroundStyle(.red).font(.caption) }; Button("Save Custom Coordinates") { _ = model.saveCustom(label: label, latitude: latitude, longitude: longitude) } }
}

private extension CLAuthorizationStatus { var label: String { switch self { case .notDetermined: "Location permission has not been requested."; case .authorized, .authorizedAlways: "Automatic location is enabled."; case .denied: "Location permission is denied."; case .restricted: "Location permission is restricted."; @unknown default: "Location permission is unavailable." } } }
