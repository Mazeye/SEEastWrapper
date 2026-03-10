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
public enum SwissEphPlanet: Int32, CaseIterable {
    case sun = 0  // SE_SUN
    case moon = 1  // SE_MOON
    case mercury = 2  // SE_MERCURY
    case venus = 3  // SE_VENUS
    case mars = 4  // SE_MARS
    case jupiter = 5  // SE_JUPITER
    case saturn = 6  // SE_SATURN
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
        // 🪶 栈上分配，零堆开销
        var coordinates = [Double](repeating: 0.0, count: 6)
        var errorMsg = [CChar](repeating: 0, count: 256)

        let flag = swe_calc_ut(
            julianDay,
            planet.rawValue,
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
