import Foundation
import PalembangKit

enum DisplayMode: String, CaseIterable, Identifiable {
    case live, pulse
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct PulseConfiguration: Equatable {
    let transitionMinutes: Double
    let holdMinutes: Double

    enum ValidationError: LocalizedError, Equatable {
        case invalidTransitionDuration
        case invalidHoldDuration

        var errorDescription: String? {
            switch self {
            case .invalidTransitionDuration: "Transition Duration must be a finite number greater than zero."
            case .invalidHoldDuration: "Hold Duration must be a finite number greater than zero."
            }
        }
    }

    init(transitionMinutes: Double, holdMinutes: Double) throws {
        guard transitionMinutes.isFinite, transitionMinutes > 0 else { throw ValidationError.invalidTransitionDuration }
        guard holdMinutes.isFinite, holdMinutes > 0 else { throw ValidationError.invalidHoldDuration }
        self.transitionMinutes = transitionMinutes
        self.holdMinutes = holdMinutes
    }

    var transitionSeconds: Double { transitionMinutes * 60 }
    var holdSeconds: Double { holdMinutes * 60 }
    var cycleSeconds: Double { 2 * holdSeconds + 2 * transitionSeconds }
}

enum PulsePhase: Equatable {
    case dayHold
    case sunset(progress: Double)
    case nightHold
    case sunrise(progress: Double)
}

enum PulseEngine {
    static func phase(at date: Date, epoch: Date, configuration: PulseConfiguration) -> PulsePhase {
        let elapsed = date.timeIntervalSince(epoch)
        let position = elapsed.truncatingRemainder(dividingBy: configuration.cycleSeconds)
        let cyclePosition = position >= 0 ? position : position + configuration.cycleSeconds
        let hold = configuration.holdSeconds
        let transition = configuration.transitionSeconds

        if cyclePosition < hold { return .dayHold }
        if cyclePosition < hold + transition { return .sunset(progress: (cyclePosition - hold) / transition) }
        if cyclePosition < 2 * hold + transition { return .nightHold }
        return .sunrise(progress: (cyclePosition - 2 * hold - transition) / transition)
    }

    static func palette(at date: Date, epoch: Date, configuration: PulseConfiguration) -> [PalembangPaletteToken: String] {
        switch phase(at: date, epoch: epoch, configuration: configuration) {
        case .dayHold: return WallpaperPalette.original.colors
        case .sunset(let progress): return transitionPalette(from: WallpaperPalette.original, through: WallpaperPalette.midnight, to: WallpaperPalette.obsidian, progress: progress)
        case .nightHold: return WallpaperPalette.obsidian.colors
        case .sunrise(let progress): return transitionPalette(from: WallpaperPalette.obsidian, through: WallpaperPalette.aurora, to: WallpaperPalette.original, progress: progress)
        }
    }

    private static func transitionPalette(from start: WallpaperPalette, through midpoint: WallpaperPalette, to end: WallpaperPalette, progress: Double) -> [PalembangPaletteToken: String] {
        if progress <= 0.5 { return PaletteEngine.blend(start.colors, midpoint.colors, amount: progress * 2) }
        return PaletteEngine.blend(midpoint.colors, end.colors, amount: (progress - 0.5) * 2)
    }
}
