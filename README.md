# Palembang Wallpaper

Palembang Wallpaper is a small native macOS ambient application. It fills its
resizable window with `PalembangView` from `PalembangSwiftUI`, including native
macOS full screen, without cropping or stretching raster artwork.

The local solar cycle drives a continuous six-token palette transition:

- Day (`solar elevation >= 0°`): Original
- Sunset: Original → Midnight → Obsidian
- Night (`<= -6°`): Obsidian
- Sunrise: Obsidian → Aurora → Original

Location permission is used only to calculate latitude/longitude for the local
solar model. Location and all solar calculations stay on-device; there is no
network request, backend, analytics, or telemetry. If access is denied, the app
shows a minimal local status message and does not invent a fallback location.

v0.1 is intentionally limited to a wallpaper-like fullscreen window. It does
not change the macOS desktop wallpaper itself and has no settings, weather,
cloud sync, or multi-monitor management.

Built using the Palembang Graphic System 0.8.0:
https://github.com/ybtiger107/palembang-graphic-system

The package's public Swift API exposes the canonical palette and six tokens,
but not its web curated-preset catalog. Therefore Original comes directly from
`Palembang.canonicalPalette`; Midnight, Aurora, and Obsidian are app-level
presets copied from the package's documented curated palette data. Rendering
remains exclusively in `PalembangSwiftUI` → `PalembangKit`.
