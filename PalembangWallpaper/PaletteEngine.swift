import Foundation
import PalembangKit

enum PaletteEngine {
    static func palette(for state: SolarState) -> [PalembangPaletteToken: String] {
        let elevation = state.elevation
        if elevation >= 0 { return WallpaperPalette.original.colors }
        if elevation <= -6 { return WallpaperPalette.obsidian.colors }

        if state.direction == .rising {
            if elevation <= -3 { return blend(WallpaperPalette.obsidian.colors, WallpaperPalette.aurora.colors, amount: (elevation + 6) / 3) }
            return blend(WallpaperPalette.aurora.colors, WallpaperPalette.original.colors, amount: (elevation + 3) / 3)
        }
        if elevation >= -3 { return blend(WallpaperPalette.original.colors, WallpaperPalette.midnight.colors, amount: -elevation / 3) }
        return blend(WallpaperPalette.midnight.colors, WallpaperPalette.obsidian.colors, amount: (elevation + 3) / -3)
    }

    static func blend(_ start: [PalembangPaletteToken: String], _ end: [PalembangPaletteToken: String], amount: Double) -> [PalembangPaletteToken: String] {
        let t = min(max(amount, 0), 1)
        return Dictionary(uniqueKeysWithValues: PalembangPaletteToken.allCases.map { token in
            (token, interpolateHex(start[token]!, end[token]!, amount: t))
        })
    }

    static func interpolateHex(_ start: String, _ end: String, amount: Double) -> String {
        let t = min(max(amount, 0), 1)
        let a = rgb(start), b = rgb(end)
        let channels = zip(a, b).map { Int(round(Double($0.0) + (Double($0.1) - Double($0.0)) * t)) }
        return String(format: "#%02X%02X%02X", channels[0], channels[1], channels[2])
    }

    private static func rgb(_ hex: String) -> [Int] {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
    }
}
