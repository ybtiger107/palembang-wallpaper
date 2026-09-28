import SwiftUI
import Foundation
import Combine
import CoreLocation
import PalembangKit
import PalembangSwiftUI

struct ContentView: View {
    @StateObject private var model = WallpaperModel()
    @State private var showingSettings = false

    var body: some View {
        Group {
            if let palette = model.palette {
                PalembangView(palette: palette)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.5), value: palette)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash").font(.title)
                    Text(model.statusMessage).multilineTextAlignment(.center)
                    HStack {
                        if model.canRequestLocation {
                            Button("Allow Location Access") { model.requestAutomaticLocation() }
                        }
                        Button("Set Location Manually") {
                            model.locationMode = .manual
                            showingSettings = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .foregroundStyle(.white)
            }
        }
        .onAppear { model.start() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { date in
            model.refresh(at: date)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingSettings = true } label: {
                    Label("Location Settings", systemImage: "location.circle")
                }
                .accessibilityLabel("Location Settings")
            }
        }
        .popover(isPresented: $showingSettings) {
            LocationSettingsView(model: model)
        }
    }
}

@MainActor
final class WallpaperModel: ObservableObject {
    @Published private(set) var palette: [PalembangPaletteToken: String]?
    @Published private(set) var statusMessage = "Location access is required to calculate the local solar cycle."
    @Published var locationMode: LocationMode {
        didSet {
            defaults.set(locationMode.rawValue, forKey: Keys.mode)
            if locationMode == .automatic { locationService.start() }
            refresh(at: Date())
        }
    }
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var automaticCoordinate: CLLocationCoordinate2D?
    @Published private(set) var manualValidationMessage: String?

    private let locationService = LocationService()
    private let defaults = UserDefaults.standard
    private var hasStarted = false

    @Published private(set) var manualCountry: String
    @Published private(set) var manualCity: String
    @Published private(set) var manualLatitude: String
    @Published private(set) var manualLongitude: String

    private enum Keys {
        static let mode = "location.mode"
        static let country = "location.manual.country"
        static let city = "location.manual.city"
        static let latitude = "location.manual.latitude"
        static let longitude = "location.manual.longitude"
    }

    init() {
        let storedMode = LocationMode(rawValue: UserDefaults.standard.string(forKey: Keys.mode) ?? "") ?? .automatic
        locationMode = storedMode
        manualCountry = UserDefaults.standard.string(forKey: Keys.country) ?? ""
        manualCity = UserDefaults.standard.string(forKey: Keys.city) ?? ""
        manualLatitude = UserDefaults.standard.string(forKey: Keys.latitude) ?? ""
        manualLongitude = UserDefaults.standard.string(forKey: Keys.longitude) ?? ""
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        locationService.start()
        syncLocationState()
        refresh(at: Date())
    }

    var canRequestLocation: Bool { authorizationStatus == .notDetermined }
    var isLocationDenied: Bool { authorizationStatus == .denied || authorizationStatus == .restricted }

    func requestAutomaticLocation() { locationMode = .automatic; locationService.requestAccess(); locationService.refreshLocation(); syncLocationState() }
    func refreshAutomaticLocation() { locationService.refreshLocation(); syncLocationState(); refresh(at: Date()) }
    func openSystemSettings() { locationService.openSystemSettings() }

    func applyManualLocation(country: String, city: String, latitude: String, longitude: String) -> Bool {
        do {
            let location = try ManualLocation(country: country, city: city, latitude: Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .nan, longitude: Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .nan)
            manualCountry = location.country; manualCity = location.city
            manualLatitude = String(location.latitude); manualLongitude = String(location.longitude)
            defaults.set(manualCountry, forKey: Keys.country); defaults.set(manualCity, forKey: Keys.city)
            defaults.set(manualLatitude, forKey: Keys.latitude); defaults.set(manualLongitude, forKey: Keys.longitude)
            manualValidationMessage = nil
            locationMode = .manual
            refresh(at: Date())
            return true
        } catch let error as ManualLocation.ValidationError {
            manualValidationMessage = error.localizedDescription
            return false
        } catch {
            manualValidationMessage = "Latitude and longitude must be valid numbers."
            return false
        }
    }

    func refresh(at date: Date) {
        syncLocationState()
        let manual = try? ManualLocation(country: manualCountry, city: manualCity, latitude: Double(manualLatitude) ?? .nan, longitude: Double(manualLongitude) ?? .nan)
        guard let coordinate = LocationSourceResolver.coordinate(mode: locationMode, automatic: automaticCoordinate, manual: manual) else {
            statusMessage = locationService.statusMessage
            if locationMode == .manual { statusMessage = "Set a valid manual latitude and longitude to calculate the solar cycle." }
            palette = nil
            return
        }
        let solarState = SolarEngine.state(at: date, latitude: coordinate.latitude, longitude: coordinate.longitude)
        palette = PaletteEngine.palette(for: solarState)
        statusMessage = ""
    }

    private func syncLocationState() {
        authorizationStatus = locationService.authorizationStatus
        automaticCoordinate = locationService.coordinate
    }

}

struct LocationSettingsView: View {
    @ObservedObject var model: WallpaperModel
    @State private var country = ""
    @State private var city = ""
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        Form {
            Picker("Location Source", selection: $model.locationMode) {
                ForEach(LocationMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            if model.locationMode == .automatic {
                Text(model.authorizationStatus.label)
                    .foregroundStyle(.secondary)
                if let coordinate = model.automaticCoordinate {
                    Text(String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                }
                HStack {
                    if model.canRequestLocation { Button("Request Access") { model.requestAutomaticLocation() } }
                    if model.isLocationDenied { Button("Open System Settings") { model.openSystemSettings() } }
                    Button("Refresh") { model.refreshAutomaticLocation() }
                }
            } else {
                TextField("Country (optional)", text: $country)
                TextField("City (optional)", text: $city)
                TextField("Latitude", text: $latitude)
                TextField("Longitude", text: $longitude)
                if let message = model.manualValidationMessage { Text(message).foregroundStyle(.red).font(.caption) }
                Button("Apply Manual Location") { _ = model.applyManualLocation(country: country, city: city, latitude: latitude, longitude: longitude) }
            }
        }
        .padding()
        .frame(width: 360)
        .onAppear {
            country = model.manualCountry; city = model.manualCity; latitude = model.manualLatitude; longitude = model.manualLongitude
        }
    }
}

private extension CLAuthorizationStatus {
    var label: String {
        switch self {
        case .notDetermined: return "Location permission has not been requested."
        case .authorized, .authorizedAlways: return "Automatic location is enabled."
        case .denied: return "Location permission is denied."
        case .restricted: return "Location permission is restricted."
        @unknown default: return "Location permission is unavailable."
        }
    }
}

#Preview { ContentView() }
