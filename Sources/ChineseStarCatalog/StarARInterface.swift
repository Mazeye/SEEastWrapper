//
//  StarARInterface.swift
//  AR 观星 — 星位置列表接口（AR 侧只依赖此协议，先用固定数据搭 AR，计算侧完成后注入真实数据）
//

import CoreLocation
import Foundation

/// 观测输入（符合 SwiftUI / CoreLocation 常用模型）
public struct StarObservationInput {
    public let date: Date
    public let coordinate: CLLocationCoordinate2D
    public let altitudeMeters: Double

    public init(date: Date, coordinate: CLLocationCoordinate2D, altitudeMeters: Double = 0) {
        self.date = date
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
    }
}

// MARK: - AR 用「单颗星」数据（由计算侧填充，AR 只负责按位置渲染）

/// 一颗在 AR 中要显示的星：用**地平坐标**表示位置，便于与设备朝向一致。
public struct StarARItem: Sendable {
    /// 唯一标识（如 "sun", "moon", "tian_shu", "mars"），用于去重或动画
    public let id: String
    /// AR 上显示的名称（如 "太阳", "天枢", "火星"）
    public let displayName: String
    /// 方位角（度，0 = 北，90 = 东，180 = 南，270 = 西）
    public let azimuthDegrees: Double
    /// 高度角（度，0 = 地平，90 = 天顶，负值表示在地平线下）
    public let altitudeDegrees: Double
    /// 可选：星等或相对亮度（越小越亮），用于控制点的大小/亮度
    public let magnitude: Double?
    /// 可选：分类，用于 AR 里不同样式（日月/行星/恒星/宿）
    public let category: StarARCategory?

    public init(
        id: String,
        displayName: String,
        azimuthDegrees: Double,
        altitudeDegrees: Double,
        magnitude: Double? = nil,
        category: StarARCategory? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.azimuthDegrees = azimuthDegrees
        self.altitudeDegrees = altitudeDegrees
        self.magnitude = magnitude
        self.category = category
    }
}

/// 星体分类（AR 可按此做不同图标/颜色）
public enum StarARCategory: String, Sendable, Codable {
    case sun
    case moon
    case planet
    case star
    case lunarMansion
}

/// AR 接受的「星位置列表」类型
public typealias StarPositionList = [StarARItem]

// MARK: - 数据提供协议（计算侧实现，AR 侧只依赖此协议）

/// 星位置数据提供者。AR 模块只依赖此协议：当前可用 Mock，后续换成真实计算实现。
public protocol StarPositionProvider: AnyObject {
    /// 返回当前应显示在 AR 中的星列表（地平坐标：方位角、高度角）
    /// - Parameters:
    ///   - date: 观测时间（用于计算侧按时间算位置；Mock 可忽略）
    ///   - location: 观测地点（用于计算侧按地点算地平坐标；Mock 可忽略）
    /// - Returns: 星位置列表，AR 按此列表渲染
    func starPositions(date: Date, location: CLLocation?) -> StarPositionList
}

extension StarPositionProvider {
    /// SwiftUI / CoreLocation 风格便捷接口：输入 Date + CLLocationCoordinate2D。
    public func starPositions(input: StarObservationInput) -> StarPositionList {
        let location = CLLocation(
            coordinate: input.coordinate,
            altitude: input.altitudeMeters,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: input.date
        )
        return starPositions(date: input.date, location: location)
    }
}

// MARK: - 固定数据 Mock（供 AR 先用固定数把界面搭起来）

/// 返回一组固定的星位置（方位角、高度角），方便 AR 先不依赖计算侧即可开发。
/// 数值为示例，仅用于布局与交互调试。
public struct MockStarData: @unchecked Sendable {

    /// 示例：约 10 颗星的固定位置（方位 0–360°，高度 10–70°）
    public static func fixedStarPositionList() -> StarPositionList {
        [
            StarARItem(
                id: "sun", displayName: "太阳", azimuthDegrees: 120, altitudeDegrees: 45,
                magnitude: -26.7, category: .sun),
            StarARItem(
                id: "moon", displayName: "月", azimuthDegrees: 200, altitudeDegrees: 35,
                magnitude: -12, category: .moon),
            StarARItem(
                id: "mars", displayName: "火星", azimuthDegrees: 180, altitudeDegrees: 50,
                magnitude: 0.5, category: .planet),
            StarARItem(
                id: "jupiter", displayName: "木星", azimuthDegrees: 250, altitudeDegrees: 25,
                magnitude: -2, category: .planet),
            StarARItem(
                id: "tian_shu", displayName: "天枢", azimuthDegrees: 15, altitudeDegrees: 55,
                magnitude: 1.8, category: .star),
            StarARItem(
                id: "tian_xuan", displayName: "天璇", azimuthDegrees: 18, altitudeDegrees: 52,
                magnitude: 2.3, category: .star),
            StarARItem(
                id: "tian_ji", displayName: "天玑", azimuthDegrees: 22, altitudeDegrees: 48,
                magnitude: 2.4, category: .star),
            StarARItem(
                id: "tian_quan", displayName: "天权", azimuthDegrees: 25, altitudeDegrees: 46,
                magnitude: 3.3, category: .star),
            StarARItem(
                id: "yu_heng", displayName: "玉衡", azimuthDegrees: 28, altitudeDegrees: 42,
                magnitude: 1.8, category: .star),
            StarARItem(
                id: "kai_yang", displayName: "开阳", azimuthDegrees: 32, altitudeDegrees: 38,
                magnitude: 2.2, category: .star),
            StarARItem(
                id: "yao_guang", displayName: "瑶光", azimuthDegrees: 38, altitudeDegrees: 32,
                magnitude: 1.9, category: .star),
            StarARItem(
                id: "polaris", displayName: "北极星", azimuthDegrees: 0, altitudeDegrees: 38,
                magnitude: 2.0, category: .star),
            StarARItem(
                id: "spica", displayName: "角宿一", azimuthDegrees: 220, altitudeDegrees: 20,
                magnitude: 1.0, category: .lunarMansion),
            StarARItem(
                id: "antares", displayName: "心宿二", azimuthDegrees: 190, altitudeDegrees: 15,
                magnitude: 1.0, category: .lunarMansion),
        ]
    }

    /// 一个实现 `StarPositionProvider` 的 Mock，始终返回固定列表（AR 可先注入此对象）
    public static var provider: StarPositionProvider { MockStarPositionProvider() }
}

/// Mock 提供者：忽略 date/location，始终返回固定列表
private final class MockStarPositionProvider: StarPositionProvider {
    func starPositions(date: Date, location: CLLocation?) -> StarPositionList {
        MockStarData.fixedStarPositionList()
    }
}
