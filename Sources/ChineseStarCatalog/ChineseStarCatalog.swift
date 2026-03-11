//
//  ChineseStarCatalog.swift
//  中国古代 AR 观星 — 基础星表（约40颗：日月、五行星、北斗七星、北极星、二十八宿距星等）
//
//  使用前请在 App 入口调用: JPLFileManager.setEphemerisPath()
//  日月与五大行星用 SwissEphemeris；北斗、北极星、二十八宿用本表或 FixedStar。
//

import Foundation
import CoreLocation

// MARK: - 星体类型（用于 AR 显示与数据源区分）

public enum ChineseStarKind {
    case sun
    case moon
    case planet(classical: ClassicalPlanet)  // 五行：水金火木土
    case bigDipper(BeiDouStar)  // 北斗七星
    case polaris  // 北极星（勾陈一）
    case lunarMansion(name: String, index: Int)  // 二十八宿，index 1...28
}

/// 五大行星（中国古代常用）
public enum ClassicalPlanet: String, CaseIterable {
    case mercury = "水星"
    case venus = "金星"
    case mars = "火星"
    case jupiter = "木星"
    case saturn = "土星"
}

/// 北斗七星星名（斗口→斗柄）
public enum BeiDouStar: String, CaseIterable {
    case tianShu = "天枢"  // 贪狼
    case tianXuan = "天璇"  // 巨门
    case tianJi = "天玑"  // 禄存
    case tianQuan = "天权"  // 文曲
    case yuHeng = "玉衡"  // 廉贞
    case kaiYang = "开阳"  // 武曲
    case yaoGuang = "瑶光"  // 破军
}

// MARK: - 赤道坐标（J2000，度）

public struct EquatorialJ2000: Decodable {
    public let raDeg: Double  // 赤经（度，0–360）
    public let decDeg: Double  // 赤纬（度，-90–90）
    public init(raDeg: Double, decDeg: Double) {
        self.raDeg = raDeg
        self.decDeg = decDeg
    }
}

// MARK: - 北斗七星 + 北极星 J2000 赤经赤纬（度，近似）
// 大熊座 αβγδεζη → 天枢～瑶光；小熊座 α → 北极星（勾陈一）

public let bigDipperAndPolarisJ2000: [(name: String, raDeg: Double, decDeg: Double)] = [
    ("天枢", 165.93, 61.75), ("天璇", 165.46, 56.38), ("天玑", 178.46, 53.70),
    ("天权", 183.86, 57.03), ("玉衡", 193.51, 55.96), ("开阳", 200.98, 54.93),
    ("瑶光", 206.89, 49.31), ("北极星", 37.96, 89.26),
]

/// 返回北斗七星 + 北极星 的 (中文名, J2000 赤道)
public func bigDipperAndPolarisCatalog() -> [(name: String, eq: EquatorialJ2000)] {
    bigDipperAndPolarisJ2000.map { entry in
        (name: entry.name, eq: EquatorialJ2000(raDeg: entry.raDeg, decDeg: entry.decDeg))
    }
}

// MARK: - 二十八宿

public let lunarMansionNames: [String] = [
    "角", "亢", "氐", "房", "心", "尾", "箕",  // 东方青龙
    "斗", "牛", "女", "虚", "危", "室", "壁",  // 北方玄武
    "奎", "娄", "胃", "昴", "毕", "觜", "参",  // 西方白虎
    "井", "鬼", "柳", "星", "张", "翼", "轸",  // 南方朱雀
]

/// 二十八宿距星（CSV 导入，J2000 赤经赤纬，单位：度）
public struct LunarMansionAnchor {
    public let mansion: String
    public let anchorName: String
    public let bayerDesignation: String
    public let standardName: String?
    public let eq: EquatorialJ2000

    public init(
        mansion: String,
        anchorName: String,
        bayerDesignation: String,
        standardName: String?,
        eq: EquatorialJ2000
    ) {
        self.mansion = mansion
        self.anchorName = anchorName
        self.bayerDesignation = bayerDesignation
        self.standardName = standardName
        self.eq = eq
    }
}

public let lunarMansionAnchorsJ2000: [LunarMansionAnchor] = [
    LunarMansionAnchor(
        mansion: "角", anchorName: "角宿一", bayerDesignation: "α Virginis", standardName: "Spica",
        eq: EquatorialJ2000(raDeg: 201.298333, decDeg: -11.161389)),
    LunarMansionAnchor(
        mansion: "亢", anchorName: "亢宿一", bayerDesignation: "κ Virginis", standardName: nil,
        eq: EquatorialJ2000(raDeg: 213.223750, decDeg: -10.274167)),
    LunarMansionAnchor(
        mansion: "氐", anchorName: "氐宿一", bayerDesignation: "α2 Librae",
        standardName: "Zubenelgenubi", eq: EquatorialJ2000(raDeg: 222.719583, decDeg: -16.041667)),
    LunarMansionAnchor(
        mansion: "房", anchorName: "房宿一", bayerDesignation: "π Scorpii", standardName: "Fang",
        eq: EquatorialJ2000(raDeg: 239.712917, decDeg: -26.114167)),
    LunarMansionAnchor(
        mansion: "心", anchorName: "心宿一", bayerDesignation: "σ Scorpii", standardName: "Alniyat",
        eq: EquatorialJ2000(raDeg: 245.297083, decDeg: -25.592778)),
    LunarMansionAnchor(
        mansion: "尾", anchorName: "尾宿一", bayerDesignation: "μ1 Scorpii", standardName: "Denebakrab",
        eq: EquatorialJ2000(raDeg: 252.967500, decDeg: -38.047500)),
    LunarMansionAnchor(
        mansion: "箕", anchorName: "箕宿一", bayerDesignation: "γ2 Sagittarii", standardName: "Alnasl",
        eq: EquatorialJ2000(raDeg: 271.452083, decDeg: -30.423611)),
    LunarMansionAnchor(
        mansion: "斗", anchorName: "斗宿一", bayerDesignation: "ϕ Sagittarii", standardName: nil,
        eq: EquatorialJ2000(raDeg: 281.414167, decDeg: -26.990833)),
    LunarMansionAnchor(
        mansion: "牛", anchorName: "牛宿一", bayerDesignation: "β Capricorni", standardName: "Dabih",
        eq: EquatorialJ2000(raDeg: 305.252917, decDeg: -14.781389)),
    LunarMansionAnchor(
        mansion: "女", anchorName: "女宿一", bayerDesignation: "ϵ Aquarii", standardName: "Albali",
        eq: EquatorialJ2000(raDeg: 311.918750, decDeg: -9.495833)),
    LunarMansionAnchor(
        mansion: "虚", anchorName: "虚宿一", bayerDesignation: "β Aquarii", standardName: "Sadalsuud",
        eq: EquatorialJ2000(raDeg: 322.889583, decDeg: -5.571111)),
    LunarMansionAnchor(
        mansion: "危", anchorName: "危宿一", bayerDesignation: "α Aquarii", standardName: "Sadalmelik",
        eq: EquatorialJ2000(raDeg: 331.445833, decDeg: -0.319722)),
    LunarMansionAnchor(
        mansion: "室", anchorName: "室宿一", bayerDesignation: "α Pegasi", standardName: "Markab",
        eq: EquatorialJ2000(raDeg: 346.190000, decDeg: 15.205278)),
    LunarMansionAnchor(
        mansion: "壁", anchorName: "壁宿一", bayerDesignation: "γ Pegasi", standardName: "Algenib",
        eq: EquatorialJ2000(raDeg: 3.309167, decDeg: 15.183611)),
    LunarMansionAnchor(
        mansion: "奎", anchorName: "奎宿二", bayerDesignation: "ζ Andromedae", standardName: nil,
        eq: EquatorialJ2000(raDeg: 11.835000, decDeg: 24.267222)),
    LunarMansionAnchor(
        mansion: "娄", anchorName: "娄宿一", bayerDesignation: "β Arietis", standardName: "Sheratan",
        eq: EquatorialJ2000(raDeg: 28.660000, decDeg: 20.808056)),
    LunarMansionAnchor(
        mansion: "胃", anchorName: "胃宿一", bayerDesignation: "35 Arietis", standardName: nil,
        eq: EquatorialJ2000(raDeg: 40.862917, decDeg: 21.173611)),
    LunarMansionAnchor(
        mansion: "昴", anchorName: "昴宿一", bayerDesignation: "17 Tauri", standardName: "Electra",
        eq: EquatorialJ2000(raDeg: 56.218750, decDeg: 24.113333)),
    LunarMansionAnchor(
        mansion: "毕", anchorName: "毕宿一", bayerDesignation: "ϵ Tauri", standardName: "Ain",
        eq: EquatorialJ2000(raDeg: 67.154167, decDeg: 19.180556)),
    LunarMansionAnchor(
        mansion: "觜", anchorName: "觜宿二", bayerDesignation: "ϕ1 Orionis", standardName: nil,
        eq: EquatorialJ2000(raDeg: 83.785000, decDeg: 9.415000)),
    LunarMansionAnchor(
        mansion: "参", anchorName: "参宿三", bayerDesignation: "δ Orionis", standardName: "Mintaka",
        eq: EquatorialJ2000(raDeg: 83.001667, decDeg: -0.299167)),
    LunarMansionAnchor(
        mansion: "井", anchorName: "井宿一", bayerDesignation: "μ Geminorum", standardName: "Tejat",
        eq: EquatorialJ2000(raDeg: 95.740000, decDeg: 22.513611)),
    LunarMansionAnchor(
        mansion: "鬼", anchorName: "鬼宿一", bayerDesignation: "θ Cancri", standardName: nil,
        eq: EquatorialJ2000(raDeg: 127.898750, decDeg: 18.094444)),
    LunarMansionAnchor(
        mansion: "柳", anchorName: "柳宿一", bayerDesignation: "δ Hydrae", standardName: nil,
        eq: EquatorialJ2000(raDeg: 129.414167, decDeg: 5.703611)),
    LunarMansionAnchor(
        mansion: "星", anchorName: "星宿一", bayerDesignation: "α Hydrae", standardName: "Alphard",
        eq: EquatorialJ2000(raDeg: 141.896667, decDeg: -8.658611)),
    LunarMansionAnchor(
        mansion: "张", anchorName: "张宿一", bayerDesignation: "υ1 Hydrae", standardName: nil,
        eq: EquatorialJ2000(raDeg: 147.869583, decDeg: -14.846667)),
    LunarMansionAnchor(
        mansion: "翼", anchorName: "翼宿一", bayerDesignation: "α Crateris", standardName: "Alkes",
        eq: EquatorialJ2000(raDeg: 164.943750, decDeg: -18.298889)),
    LunarMansionAnchor(
        mansion: "轸", anchorName: "轸宿一", bayerDesignation: "γ Corvi", standardName: "Gienah",
        eq: EquatorialJ2000(raDeg: 183.951667, decDeg: -17.541944)),
]

/// 快速按宿名取 J2000 赤道坐标（例如: lunarMansionEquatorialJ2000["角"]）
public var lunarMansionEquatorialJ2000: [String: EquatorialJ2000] {
    Dictionary(uniqueKeysWithValues: lunarMansionAnchorsJ2000.map { ($0.mansion, $0.eq) })
}

/// 与 SwissEphemeris FixedStar 能对应的宿（宿名 -> 库内枚举）
/// 其余宿需自建 RA/Dec 表（如从《中国天文年历》或星表查距星）。
public var lunarMansionToFixedStar: [String: String] {
    [
        "角": "Spica", "心": "Antares", "毕": "Aldebaran", "星": "Regulus",
        "昴": "Alcyone",  // 昴宿一，库可能用 Alcyone
    ]
}

// MARK: - 使用 CSwissEphemeris 取日月与五行星（需在 App 中调用）

/// 将 ClassicalPlanet 与 SwissEphPlanet 对应
public func classicalPlanetToSwiss(_ p: ClassicalPlanet) -> SwissEphPlanet {
    switch p {
    case .mercury: return .mercury
    case .venus: return .venus
    case .mars: return .mars
    case .jupiter: return .jupiter
    case .saturn: return .saturn
    }
}

/// 一次取齐：日、月、五行星 的黄道坐标（用于后续转地平）
public func sunMoonPlanetsCoordinates(date: Date) -> [(String, longitude: Double, latitude: Double)]
{
    var list: [(String, Double, Double)] = []
    let jd = SwissEphBridge.julianDay(from: date)

    if let sun = SwissEphBridge.calculateCoordinates(planet: .sun, julianDay: jd) {
        list.append(("日", sun.longitude, sun.latitude))
    }
    if let moon = SwissEphBridge.calculateCoordinates(planet: .moon, julianDay: jd) {
        list.append(("月", moon.longitude, moon.latitude))
    }
    for p in ClassicalPlanet.allCases {
        if let coord = SwissEphBridge.calculateCoordinates(
            planet: classicalPlanetToSwiss(p), julianDay: jd)
        {
            list.append((p.rawValue, coord.longitude, coord.latitude))
        }
    }
    return list
}

// MARK: - 月相 (Moon Phase)

/// 月相数据模型
public struct MoonPhase: Codable, Sendable {
    /// 月亮被照亮的比例，范围 [0.0, 1.0]。0 代表新月，1 代表满月。
    public let percentage: Double
    /// 月相角（度）。0度为新月，180度为满月。
    public let phaseAngle: Double
    /// 是否处于盈长状态（月相越来越满）。如果为 false，则是亏缺状态。
    public let isWaxing: Bool
    
    public init(percentage: Double, phaseAngle: Double, isWaxing: Bool) {
        self.percentage = percentage
        self.phaseAngle = phaseAngle
        self.isWaxing = isWaxing
    }
}

/// 计算指定时间与地点（可选）的月相信息。
/// 如果提供了位置，将采用更加精准的地平站心坐标（Topocentric）修正。
/// - Parameters:
///   - date: 观测时间
///   - location: 观测地点（可选）
/// - Returns: 月相信息，如果计算失败则返回 nil。
public func calculateMoonPhase(date: Date, location: CLLocation? = nil) -> MoonPhase? {
    let jd = SwissEphBridge.julianDay(from: date)
    let alt = location?.altitude ?? 0.0
    
    guard let result = SwissEphBridge.calculateMoonPhase(
        julianDay: jd, 
        location: location?.coordinate, 
        altitude: alt
    ) else {
        return nil
    }
    
    return MoonPhase(
        percentage: result.percentage,
        phaseAngle: result.phaseAngle,
        isWaxing: result.isWaxing
    )
}
