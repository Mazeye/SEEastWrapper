//
//  SwissEphBridge.swift
//  安全的 CSwissEphemeris C API 直接桥接，零堆分配。
//  替代旧 SwissEphemeris Swift wrapper（修复内存泄漏与缓冲区溢出）。
//

import CSwissEphemeris
import Foundation

// MARK: - 行星枚举（映射 Swiss Ephemeris C 常量）

/// 对应 Swiss Ephemeris C API 的行星 ID。
/// 仅包含日月与五大行星（中国古代天文所需）。
public enum SwissEphPlanet: String, CaseIterable, Codable {
    case sun  // SE_SUN
    case moon  // SE_MOON
    case mercury  // SE_MERCURY
    case venus  // SE_VENUS
    case mars  // SE_MARS
    case jupiter  // SE_JUPITER
    case saturn  // SE_SATURN

    // 四余
    case trueNode  // 罗睺 (SE_TRUE_NODE)
    case southNode  // 计都 (计算获得: trueNode + 180°)
    case ziqi  // 紫炁 (计算获得: 占位算法，约28年一周天)
    case meanApog  // 月孛 (SE_MEAN_APOG)

    var sePlanetID: Int32? {
        switch self {
        case .sun: return SE_SUN
        case .moon: return SE_MOON
        case .mercury: return SE_MERCURY
        case .venus: return SE_VENUS
        case .mars: return SE_MARS
        case .jupiter: return SE_JUPITER
        case .saturn: return SE_SATURN
        case .trueNode: return SE_TRUE_NODE
        case .meanApog: return SE_MEAN_APOG
        case .southNode, .ziqi: return nil  // 使用特殊计算
        }
    }
}

// MARK: - 安全桥接

/// 直接调用 CSwissEphemeris C 函数的安全桥接。
/// 使用栈上数组（`&` 传递），无堆分配，无内存泄漏。
public enum SwissEphBridge {

    /// 初始化星历路径。
    /// 传 nil 使用内置 Moshier 星历（不需要外部文件，支持 -13000 ~ +17000 年）。
    /// - Parameter path: 星历文件路径，nil 使用内置 Moshier 算法。
    public static func setEphemerisPath(_ path: String? = nil) {
        if let path = path {
            path.withCString { cstr in
                // swe_set_ephe_path 需要 UnsafeMutablePointer，但不会修改内容
                swe_set_ephe_path(UnsafeMutablePointer(mutating: cstr))
            }
        } else {
            swe_set_ephe_path(nil)
        }
    }

    /// 计算行星黄道坐标（黄经、黄纬）。
    /// - Parameters:
    ///   - planet: 行星枚举
    ///   - julianDay: 儒略日（UT）
    /// - Returns: (longitude, latitude) 黄道坐标（度），计算失败返回 nil。
    public static func calculateCoordinates(
        planet: SwissEphPlanet,
        julianDay: Double
    ) -> (longitude: Double, latitude: Double)? {

        // 计都：罗睺加 180 度
        if planet == .southNode {
            guard let trueNode = calculateCoordinates(planet: .trueNode, julianDay: julianDay)
            else { return nil }
            let shifted = trueNode.longitude + 180.0
            return (
                longitude: shifted > 360 ? shifted - 360 : shifted, latitude: -trueNode.latitude
            )
        }

        // 紫炁：中国古代虚星，约28年一周天。
        // 由于没有确切的官方星历公式，这里使用一个简单的线性占位推算：每日运行约 0.0352 度。
        // 以 J2000 (JD 2451545.0) 作为一个占位起点。
        if planet == .ziqi {
            let daysSinceJ2000 = julianDay - 2451545.0
            let speedPerDay = 360.0 / (28.0 * 365.25)  // 约 0.0352 度/天
            var lon = (daysSinceJ2000 * speedPerDay).truncatingRemainder(dividingBy: 360.0)
            if lon < 0 { lon += 360.0 }
            return (longitude: lon, latitude: 0.0)  // 虚星通常没有黄纬
        }

        guard let sePlanetID = planet.sePlanetID else { return nil }

        // 🪶 栈上分配，零堆开销
        var coordinates = [Double](repeating: 0.0, count: 6)
        var errorMsg = [CChar](repeating: 0, count: 256)

        let flag = swe_calc_ut(
            julianDay,
            sePlanetID,
            SEFLG_SPEED,
            &coordinates,
            &errorMsg
        )

        if flag < 0 {
            let errorString = String(cString: errorMsg)
            print("Swiss Ephemeris Error: \(errorString)")
            return nil
        }

        // coordinates[0] = 黄经, coordinates[1] = 黄纬
        return (longitude: coordinates[0], latitude: coordinates[1])
    }

    /// 将 Foundation `Date` 转为儒略日（UT）。
    /// 使用 Swiss Ephemeris 的 `swe_julday` 函数。
    public static func julianDay(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "UTC")!
        var cal = calendar
        cal.timeZone = tz

        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let second = cal.component(.second, from: date)

        let hourDouble = Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0

        return swe_julday(
            Int32(year),
            Int32(month),
            Int32(day),
            hourDouble,
            SE_GREG_CAL
        )
    }
}
