import SwiftUI
import Combine
import CoreLocation
import PalembangKit
import PalembangSwiftUI

struct ContentView: View {
    @StateObject private var model = WallpaperModel()

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
    }
}

@MainActor
final class WallpaperModel: ObservableObject {
    @Published private(set) var palette: [PalembangPaletteToken: String]?
    @Published private(set) var statusMessage = "Location access is required to calculate the local solar cycle."

    private let locationService = LocationService()
    private var hasStarted = false

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        locationService.start()
        refresh(at: Date())
    }

    func refresh(at date: Date) {
        guard let coordinate = locationService.coordinate else {
            statusMessage = locationService.statusMessage
            palette = nil
            return
        }
        let solarState = SolarEngine.state(at: date, latitude: coordinate.latitude, longitude: coordinate.longitude)
        palette = PaletteEngine.palette(for: solarState)
        statusMessage = ""
    }
}

#Preview { ContentView() }
