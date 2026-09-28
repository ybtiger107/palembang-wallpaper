import PalembangKit

struct WallpaperPalette: Equatable {
    let name: String
    let colors: [PalembangPaletteToken: String]

    static let original = WallpaperPalette(name: "Original", colors: Palembang.canonicalPalette)
    static let midnight = WallpaperPalette(name: "Midnight", colors: [
        .skyHot: "#C2678D", .skyCool: "#2B2D52", .seaLight: "#3A3F6B", .seaDark: "#14162B", .seaHaze: "#8892B0", .seaGlow: "#4C6FA5"
    ])
    static let aurora = WallpaperPalette(name: "Aurora", colors: [
        .skyHot: "#7EE3B5", .skyCool: "#4A3F7A", .seaLight: "#5B7A8C", .seaDark: "#22263F", .seaHaze: "#B9C9D6", .seaGlow: "#8A5FBE"
    ])
    static let obsidian = WallpaperPalette(name: "Obsidian", colors: [
        .skyHot: "#8A6D4E", .skyCool: "#14171C", .seaLight: "#23262E", .seaDark: "#05060A", .seaHaze: "#3D4148", .seaGlow: "#2E4A52"
    ])
}
