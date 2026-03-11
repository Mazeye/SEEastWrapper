# SEEastWrapper

[中文](README.md) | [日本語](README_JP.md)

SEEastWrapper is a Swift Package for AR-oriented sky position calculation.  
It outputs horizontal coordinates (azimuth/altitude) that can be used directly in ARKit rendering.

## Installation

Add this package in your app `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/SEEastWrapper.git", from: "0.1.0")
]
```

Then add the product to your target:

```swift
.product(
    name: "SEEastWrapper",
    package: "SEEastWrapper"
)
```

`SEEastWrapper` depends on the maintainer's SwissEphemeris fork (`main` branch):

```swift
.package(url: "https://github.com/Mazeye/SwissEphemeris.git", branch: "main")
```

## Quick Start

```swift
import CoreLocation
import SEEastWrapper

let provider = RealStarPositionProvider()
let input = StarObservationInput(
    date: Date(),
    coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
)
let stars = provider.starPositions(input: input)
```

Default output includes:

- 28 Lunar Mansions
- Sun
- Moon
- Celestial Pole (`tianji`)
- Five classical planets (Mercury, Venus, Mars, Jupiter, Saturn)

Each `StarPositionList` item contains:

- `azimuthDegrees`
- `altitudeDegrees`
- `id` / `displayName` / `category`

## Extend Celestial Objects

You can add objects by configuration only:

- Standard name: `.standardName("Spica")`
- Or J2000 coordinate: `.j2000(EquatorialJ2000(raDeg: ..., decDeg: ...))`

Then pass custom objects to:

```swift
RealStarPositionProvider(objects:)
```

## Get Local Moon Phase

The library provides an interface `calculateMoonPhase` for calculating the exact moon phase for a given time and optional location:

```swift
import CoreLocation
import SEEastWrapper

let date = Date() // Current time
let beijing = CLLocation(latitude: 39.9042, longitude: 116.4074)

if let moonPhase = calculateMoonPhase(date: date, location: beijing) {
    print("Illuminated percentage: \(moonPhase.percentage)") // 0.0 ~ 1.0
    print("Phase angle: \(moonPhase.phaseAngle)") // 0 ~ 360 degrees
    print("Is waxing: \(moonPhase.isWaxing)")
}
```

If no `location` is provided, geocentric calculation is used. Providing a `location` applies a topocentric correction which yields more precise results.

## CLI Debugging

You can query any time/location directly from CLI:

```bash
swift run SEEastWrapperDebugCLI --date 2026-03-09T20:00:00+08:00 --lat 39.9042 --lon 116.4074 --visible-only
```

Common options:

- `--date`: ISO8601 time
- `--lat` / `--lon`: latitude / longitude
- `--visible-only`: only show objects above horizon
- `--category`: `sun|moon|planet|star|lunarMansion`
- `--limit`: show top N results

## Credits and License

- This project is built on top of the Swiss Ephemeris Swift wrapper ecosystem. Thanks to Vincent Smithers and contributors. Original repository: [`vsmithers1087/SwissEphemeris`](https://github.com/vsmithers1087/SwissEphemeris) (archived).
- This project depends on the maintained fork: [`Mazeye/SwissEphemeris`](https://github.com/Mazeye/SwissEphemeris).
- The upstream project uses GNU General Public License (GPL-2.0 or later). This project is distributed in a GPL-compatible manner. Keep license/copyright notices and provide corresponding source when redistributing.
