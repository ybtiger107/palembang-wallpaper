# Palembang Wallpaper

Palembang Wallpaper is a small native macOS ambient application. It fills its
resizable window with `PalembangView` from `PalembangSwiftUI`, including native
macOS full screen, without cropping or stretching raster artwork.

The local solar cycle drives a continuous six-token palette transition:

- Day (`solar elevation >= 0°`): Original
- Sunset: Original → Midnight → Obsidian
- Night (`<= -6°`): Obsidian
- Sunrise: Obsidian → Aurora → Original

Location offers Automatic (CoreLocation), City, and Custom Coordinates. The
city catalog is a small bundled offline catalog; selecting a city never makes a
network or geocoding request. Custom Coordinates is an advanced fallback for
unsupported cities, precise preferences, and testing. All location and solar
calculations stay on-device; there is no backend, analytics, telemetry, or
location upload.

Location controls are available through the native macOS menu bar and compact
Settings window. The artwork surface remains clean, including in fullscreen;
move the pointer to the top edge to reveal the macOS menu bar.

v0.1 is intentionally limited to a wallpaper-like fullscreen window. It does
not change the macOS desktop wallpaper itself and has no weather, cloud sync,
or multi-monitor management.

Built using the Palembang Graphic System 0.8.0:
https://github.com/ybtiger107/palembang-graphic-system

The package's public Swift API exposes the canonical palette and six tokens,
but not its web curated-preset catalog. Therefore Original comes directly from
`Palembang.canonicalPalette`; Midnight, Aurora, and Obsidian are app-level
presets copied from the package's documented curated palette data. Rendering
remains exclusively in `PalembangSwiftUI` → `PalembangKit`.
