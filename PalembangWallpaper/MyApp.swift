import SwiftUI
import AppKit

@main struct MyApp: App {
    @StateObject private var model = WallpaperModel()
    @NSApplicationDelegateAdaptor(MenuOrderDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(model) }
        Settings { LocationSettingsView().environmentObject(model) }
        .commands { AppCommands(model: model) }
    }
}

struct AppCommands: Commands {
    @ObservedObject var model: WallpaperModel
    @Environment(\.openSettings) private var openSettings
    var body: some Commands {
        CommandMenu("Location") {
            Button("Automatic Location") { model.selectMode(.automatic) }
            Button("Refresh Current Location") { model.refreshAutomaticLocation() }
            Divider()
            Button("Choose City…") { model.selectMode(.city); openSettings() }
            Button("Custom Coordinates…") { model.selectMode(.custom); openSettings() }
            if model.isLocationDenied { Button("Open Location Settings…") { model.openSystemSettings() } }
        }
    }
}

final class MenuOrderDelegate: NSObject, NSApplicationDelegate {
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let mainMenu = NSApp.mainMenu {
            observers.append(NotificationCenter.default.addObserver(forName: NSMenu.didAddItemNotification, object: mainMenu, queue: .main) { [weak self] _ in
                self?.scheduleLocationMenuReorder()
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scheduleLocationMenuReorder()
        })
        scheduleLocationMenuReorder()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // SwiftUI may rebuild the menu after a Settings window changes focus.
        scheduleLocationMenuReorder()
    }

    private func scheduleLocationMenuReorder() {
        DispatchQueue.main.async { self.moveLocationMenuAfterApplicationMenu() }
    }

    private func moveLocationMenuAfterApplicationMenu() {
        guard let mainMenu = NSApp.mainMenu,
              let locationItem = mainMenu.items.first(where: { $0.title == "Location" }),
              mainMenu.items.count > 1 else { return }
        let currentIndex = mainMenu.index(of: locationItem)
        guard currentIndex != 1 else { return }
        mainMenu.removeItem(at: currentIndex)
        mainMenu.insertItem(locationItem, at: 1)
    }
}
