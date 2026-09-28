import SwiftUI

@main struct MyApp: App {
    @StateObject private var model = WallpaperModel()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(model) }
        Settings { LocationSettingsView().environmentObject(model) }
        .commands { AppCommands(model: model) }
    }
}

struct AppCommands: Commands {
    @ObservedObject var model: WallpaperModel
    var body: some Commands {
        CommandMenu("Location") {
            Button("Automatic Location") { model.selectMode(.automatic) }
            Button("Refresh Current Location") { model.refreshAutomaticLocation() }
            Divider()
            Button("Choose City…") { model.selectMode(.city) }
            if model.isLocationDenied { Button("Open Location Settings…") { model.openSystemSettings() } }
        }
    }
}
