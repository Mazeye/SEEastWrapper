//
//  RealStarPositionProvider.swift
//  计算侧实现：根据 date + location 用星历算出地平坐标，返回 StarPositionList。
//  TDD：先写测试，本实现从"返回空列表"开始，直至通过全部测试再接到 AR。
//

import CoreLocation
import Foundation

/// 天体坐标输入源：可用标准名（星表名）或直接给 J2000 赤道坐标。
public enum CelestialCoordinateSource {
    case standardName(String)
    case j2000(EquatorialJ2000)
    case swissPlanet(SwissEphPlanet)
}

/// 可扩展天体配置：后续新增天体时只需追加配置。
public struct CelestialObjectConfig {
    public let id: String
    public let displayName: String
    public let category: StarARCategory
    public let magnitude: Double?
    public let source: CelestialCoordinateSource

    public init(
        id: String,
        displayName: String,
        category: StarARCategory,
        magnitude: Double? = nil,
        source: CelestialCoordinateSource
    ) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.magnitude = magnitude
        self.source = source
    }
}

/// 真实星位置提供者：
/// 输入时间 + 位置信息，输出可直接给 ARKit 的地平坐标（方位角/高度角）。
/// 当前默认使用 J2000 近似（未做岁差/章动改正），适合先跑通 AR 与接口联调。
public final class RealStarPositionProvider: StarPositionProvider {
    private let objects: [CelestialObjectConfig]
    private let standardNameLookup: [String: EquatorialJ2000]

    /// 默认初始化：返回二十八宿 + 日/月 + 天极 + 五大行星。
    public convenience init() {
        self.init(objects: Self.defaultObjects())
    }

    /// 自定义初始化：可传入任意天体配置数组，支持按标准名或 J2000 扩展。
    public init(objects: [CelestialObjectConfig]) {
        self.objects = objects
        self.standardNameLookup = Self.buildStandardNameLookup()
    }

    public func starPositions(date: Date, location: CLLocation?) -> StarPositionList {
        guard let location else { return [] }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        return objects.compactMap { obj in
            guard let eq = resolveEquatorialCoordinate(for: obj, date: date) else { return nil }
            let horizontal = Self.equatorialToHorizontal(
                date: date,
                raDeg: eq.raDeg,
                decDeg: eq.decDeg,
                observerLatDeg: lat,
                observerLonDeg: lon
            )
            return StarARItem(
                id: obj.id,
                displayName: obj.displayName,
                azimuthDegrees: horizontal.azimuthDeg,
                altitudeDegrees: horizontal.altitudeDeg,
                magnitude: obj.magnitude,
                category: obj.category
            )
        }
    }

    // MARK: - 默认配置（基础观星目标）

    public static func defaultObjects() -> [CelestialObjectConfig] {
        var objects = defaultLunarMansionObjects()
        objects.append(contentsOf: defaultCoreSkyObjects())
        return objects
    }

    public static func defaultLunarMansionObjects() -> [CelestialObjectConfig] {
        lunarMansionAnchorsJ2000.map { anchor in
            CelestialObjectConfig(
                id: "lm_\(anchor.mansion)",
                displayName: "\(anchor.mansion)宿",
                category: .lunarMansion,
                source: .j2000(anchor.eq)
            )
        }
    }

    /// 日/月/天极/五大行星
    public static func defaultCoreSkyObjects() -> [CelestialObjectConfig] {
        var objects: [CelestialObjectConfig] = [
            CelestialObjectConfig(
                id: "tianji",
                displayName: "天极",
                category: .star,
                source: .j2000(EquatorialJ2000(raDeg: 37.96, decDeg: 89.26))
            )
        ]

        objects.append(
            contentsOf: [
                CelestialObjectConfig(
                    id: "sun", displayName: "日", category: .sun, source: .swissPlanet(.sun)),
                CelestialObjectConfig(
                    id: "moon", displayName: "月", category: .moon, source: .swissPlanet(.moon)),
                CelestialObjectConfig(
                    id: "mercury", displayName: "水星", category: .planet,
                    source: .swissPlanet(.mercury)),
                CelestialObjectConfig(
                    id: "venus", displayName: "金星", category: .planet, source: .swissPlanet(.venus)),
                CelestialObjectConfig(
                    id: "mars", displayName: "火星", category: .planet, source: .swissPlanet(.mars)),
                CelestialObjectConfig(
                    id: "jupiter", displayName: "木星", category: .planet,
                    source: .swissPlanet(.jupiter)),
                CelestialObjectConfig(
                    id: "saturn", displayName: "土星", category: .planet,
                    source: .swissPlanet(.saturn)),
            ]
        )
        return objects
    }

    // MARK: - 内部工具

    private func resolveEquatorialCoordinate(for object: CelestialObjectConfig, date: Date)
        -> EquatorialJ2000?
    {
        switch object.source {
        case .j2000(let eq):
            return eq
        case .standardName(let name):
            return standardNameLookup[name.lowercased()]
        case .swissPlanet(let planet):
            let jd = SwissEphBridge.julianDay(from: date)
            guard let coord = SwissEphBridge.calculateCoordinates(planet: planet, julianDay: jd)
            else {
                return nil
            }
            return Self.eclipticToEquatorial(
                longitudeDeg: coord.longitude,
                latitudeDeg: coord.latitude,
                date: date
            )
        }
    }

    private static func buildStandardNameLookup() -> [String: EquatorialJ2000] {
        var lookup: [String: EquatorialJ2000] = [:]
        for anchor in lunarMansionAnchorsJ2000 {
            if let standardName = anchor.standardName?.lowercased(), !standardName.isEmpty {
                lookup[standardName] = anchor.eq
            }
        }
        for entry in bigDipperAndPolarisJ2000 {
            lookup[entry.name.lowercased()] = EquatorialJ2000(
                raDeg: entry.raDeg, decDeg: entry.decDeg)
        }
        return lookup
    }

    /// 黄道坐标 -> 赤道坐标（简化，足够用于 AR 定位展示）
    private static func eclipticToEquatorial(
        longitudeDeg: Double,
        latitudeDeg: Double,
        date: Date
    ) -> EquatorialJ2000 {
        let lambda = deg2rad(longitudeDeg)
        let beta = deg2rad(latitudeDeg)
        let epsilon = deg2rad(meanObliquityOfEcliptic(date: date))

        let sinDec = sin(beta) * cos(epsilon) + cos(beta) * sin(epsilon) * sin(lambda)
        let dec = asin(sinDec)

        let y = sin(lambda) * cos(epsilon) - tan(beta) * sin(epsilon)
        let x = cos(lambda)
        let ra = atan2(y, x)

        return EquatorialJ2000(
            raDeg: normalizeDegrees(rad2deg(ra)),
            decDeg: rad2deg(dec)
        )
    }

    /// 平黄赤交角（度）
    private static func meanObliquityOfEcliptic(date: Date) -> Double {
        let jd = julianDay(date: date)
        let t = (jd - 2451545.0) / 36525.0
        return 23.439291 - 0.0130042 * t
    }

    /// 赤道坐标 (RA/Dec) -> 地平坐标 (Az/Alt)，单位均为度。
    private static func equatorialToHorizontal(
        date: Date,
        raDeg: Double,
        decDeg: Double,
        observerLatDeg: Double,
        observerLonDeg: Double
    ) -> (azimuthDeg: Double, altitudeDeg: Double) {
        let lstDeg = localSiderealTimeDegrees(date: date, observerLongitudeDeg: observerLonDeg)
        let hourAngleDeg = normalizeDegrees(lstDeg - raDeg)

        let ha = deg2rad(hourAngleDeg)
        let dec = deg2rad(decDeg)
        let lat = deg2rad(observerLatDeg)

        let sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha)
        let alt = asin(sinAlt)
        let cosAlt = max(1e-12, cos(alt))

        let sinAz = -cos(dec) * sin(ha) / cosAlt
        let cosAz = (sin(dec) - sin(alt) * sin(lat)) / (cosAlt * cos(lat))
        let az = atan2(sinAz, cosAz)

        return (normalizeDegrees(rad2deg(az)), rad2deg(alt))
    }

    /// 地方恒星时（度，0-360）。
    private static func localSiderealTimeDegrees(date: Date, observerLongitudeDeg: Double) -> Double
    {
        let jd = julianDay(date: date)
        let t = (jd - 2451545.0) / 36525.0
        let gmst =
            280.46061837
            + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * t * t
            - (t * t * t) / 38710000.0
        return normalizeDegrees(gmst + observerLongitudeDeg)
    }

    private static func julianDay(date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func deg2rad(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private static func rad2deg(_ rad: Double) -> Double { rad * 180.0 / .pi }

    private static func normalizeDegrees(_ value: Double) -> Double {
        var x = value.truncatingRemainder(dividingBy: 360.0)
        if x < 0 { x += 360.0 }
        return x
    }
}
