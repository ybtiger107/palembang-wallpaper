# Palembang Wallpaper

Palembang Wallpaper is a native macOS ambient application that fills a
resizable or fullscreen window with Palembang rendering. It is wallpaper-like,
but does not replace the actual macOS desktop wallpaper.

## Modes

- **Live** follows the local solar cycle using the configured location.
- **Pulse** runs an independent, configurable day/night palette cycle and does
  not require location permission.

Location can be **Automatic** (Core Location), an offline **City**, or
**Custom Coordinates**. The city catalog and all solar/location calculations
are local; there is no backend, geocoding, weather API, analytics, telemetry,
or location upload.

Native macOS Location and Mode menus, Settings tabs, resizable rendering, and
fullscreen use are included. Preferences persist across launches.

## Requirements

- macOS 26.7 or later
- Xcode 27 or later for a source/development build

To build from source, clone this repository, open `PalembangWallpaper.xcodeproj`
in Xcode, and build/run the `PalembangWallpaper` scheme. No signed or
notarized standalone application is included in v0.1.0.

Built using the Palembang Graphic System 0.8.0:
https://github.com/ybtiger107/palembang-graphic-system
