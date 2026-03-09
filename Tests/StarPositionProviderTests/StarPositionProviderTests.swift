//
//  StarPositionProviderTests.swift
//  TDD：先写测试，计算侧实现 StarPositionProvider 直至全部通过，再接到 AR。
//

import XCTest
import CoreLocation
@testable import SEEastWrapper
import SwissEphemeris

final class StarPositionProviderTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        JPLFileManager.setEphemerisPath()
    }

    private let beijing = CLLocation(latitude: 39.9042, longitude: 116.4074)
    /// 北京 2024-06-15 22:00 北京时间 ≈ 14:00 UTC（夜间，可见北极星）
    private var nightInBeijing: Date {
        var c = DateComponents()
        c.year = 2024; c.month = 6; c.day = 15; c.hour = 14; c.minute = 0
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    // MARK: - 1. 接口契约：任意 Provider 返回的列表必须满足的结构

    func testProviderReturnsValidListStructure() {
        let provider: StarPositionProvider = MockStarData.provider
        let list = provider.starPositions(date: Date(), location: nil)
        XCTAssertFalse(list.isEmpty, "列表不应为空")
        for item in list {
            XCTAssertFalse(item.id.isEmpty, "id 不应为空: \(item.id)")
            XCTAssertFalse(item.displayName.isEmpty, "displayName 不应为空: \(item.id)")
            XCTAssert(item.azimuthDegrees >= 0 && item.azimuthDegrees < 360,
                      "方位角应在 [0, 360): \(item.id) = \(item.azimuthDegrees)")
            XCTAssert(item.altitudeDegrees >= -90 && item.altitudeDegrees <= 90,
                      "高度角应在 [-90, 90]: \(item.id) = \(item.altitudeDegrees)")
        }
    }

    /// 真实 Provider 也必须满足相同结构（用 Real 跑时再验证）
    func testRealProviderReturnsValidListStructure() {
        let provider: StarPositionProvider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        if list.isEmpty { return } // 尚未实现时跳过结构检查
        for item in list {
            XCTAssertFalse(item.id.isEmpty, "id 不应为空: \(item.id)")
            XCTAssertFalse(item.displayName.isEmpty, "displayName 不应为空: \(item.id)")
            XCTAssert(item.azimuthDegrees >= 0 && item.azimuthDegrees < 360,
                      "方位角应在 [0, 360): \(item.id) = \(item.azimuthDegrees)")
            XCTAssert(item.altitudeDegrees >= -90 && item.altitudeDegrees <= 90,
                      "高度角应在 [-90, 90]: \(item.id) = \(item.altitudeDegrees)")
        }
    }

    // MARK: - 2. Mock 行为（固定数据）

    func testMockProviderReturnsFixedCount() {
        let list = MockStarData.fixedStarPositionList()
        XCTAssertEqual(list.count, 14, "Mock 固定列表应为 14 颗星")
    }

    func testMockProviderContainsRequiredIds() {
        let list = MockStarData.fixedStarPositionList()
        let ids = Set(list.map(\.id))
        XCTAssertTrue(ids.contains("sun"), "应包含太阳")
        XCTAssertTrue(ids.contains("moon"), "应包含月")
        XCTAssertTrue(ids.contains("polaris"), "应包含北极星")
        XCTAssertTrue(ids.contains("tian_shu"), "应包含天枢")
        XCTAssertTrue(ids.contains("mars"), "应包含火星")
    }

    // MARK: - 3. 真实 Provider：默认二十八宿 + 可配置扩展

    func testRealProviderDefaultReturnsLunarMansionsAndCoreObjects() {
        let provider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        XCTAssertEqual(list.count, 36, "默认应返回二十八宿 + 日/月/天极/五大行星")
    }

    func testRealProviderDefaultContainsBoundaryMansionIds() {
        let provider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        let ids = Set(list.map(\.id))
        XCTAssertTrue(ids.contains("lm_角"))
        XCTAssertTrue(ids.contains("lm_轸"))
        XCTAssertTrue(ids.contains("sun"))
        XCTAssertTrue(ids.contains("moon"))
        XCTAssertTrue(ids.contains("tianji"))
        XCTAssertTrue(ids.contains("mercury"))
        XCTAssertTrue(ids.contains("venus"))
        XCTAssertTrue(ids.contains("mars"))
        XCTAssertTrue(ids.contains("jupiter"))
        XCTAssertTrue(ids.contains("saturn"))
    }

    func testSwiftUICoordinateInputConvenienceAPI() {
        let provider = RealStarPositionProvider()
        let input = StarObservationInput(
            date: nightInBeijing,
            coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            altitudeMeters: 0
        )
        let list = provider.starPositions(input: input)
        XCTAssertEqual(list.count, 36)
    }

    func testProviderCanExtendByJ2000Coordinate() {
        let custom = CelestialObjectConfig(
            id: "custom_star",
            displayName: "自定义星",
            category: .star,
            source: .j2000(EquatorialJ2000(raDeg: 10, decDeg: 20))
        )
        let provider = RealStarPositionProvider(objects: [custom])
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list.first?.id, "custom_star")
    }

    func testProviderCanResolveByStandardName() {
        let custom = CelestialObjectConfig(
            id: "spica_test",
            displayName: "角宿一",
            category: .lunarMansion,
            source: .standardName("Spica")
        )
        let provider = RealStarPositionProvider(objects: [custom])
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        XCTAssertEqual(list.count, 1, "应能通过标准名解析到 J2000 坐标")
        XCTAssertEqual(list.first?.id, "spica_test")
    }
}
