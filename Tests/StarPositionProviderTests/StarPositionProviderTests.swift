//
//  StarPositionProviderTests.swift
//  TDD：先写测试，计算侧实现 StarPositionProvider 直至全部通过，再接到 AR。
//

import CoreLocation
import XCTest

@testable import SEEastWrapper

final class StarPositionProviderTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        SwissEphBridge.setEphemerisPath()
    }

    private let beijing = CLLocation(latitude: 39.9042, longitude: 116.4074)
    /// 北京 2024-06-15 22:00 北京时间 ≈ 14:00 UTC（夜间，可见北极星）
    private var nightInBeijing: Date {
        var c = DateComponents()
        c.year = 2024
        c.month = 6
        c.day = 15
        c.hour = 14
        c.minute = 0
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
            XCTAssert(
                item.azimuthDegrees >= 0 && item.azimuthDegrees < 360,
                "方位角应在 [0, 360): \(item.id) = \(item.azimuthDegrees)")
            XCTAssert(
                item.altitudeDegrees >= -90 && item.altitudeDegrees <= 90,
                "高度角应在 [-90, 90]: \(item.id) = \(item.altitudeDegrees)")
        }
    }

    /// 真实 Provider 也必须满足相同结构（用 Real 跑时再验证）
    func testRealProviderReturnsValidListStructure() {
        let provider: StarPositionProvider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        if list.isEmpty { return }  // 尚未实现时跳过结构检查
        for item in list {
            XCTAssertFalse(item.id.isEmpty, "id 不应为空: \(item.id)")
            XCTAssertFalse(item.displayName.isEmpty, "displayName 不应为空: \(item.id)")
            XCTAssert(
                item.azimuthDegrees >= 0 && item.azimuthDegrees < 360,
                "方位角应在 [0, 360): \(item.id) = \(item.azimuthDegrees)")
            XCTAssert(
                item.altitudeDegrees >= -90 && item.altitudeDegrees <= 90,
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

    // MARK: - 3. 真实 Provider：基于 JSON 配置

    func testRealProviderLoadsFromJSON() {
        let provider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        // 28 宿 + 日月 (2) + 五星 (5) + 四余 (4) + 北斗 (7) + 北极星 (1) = 47
        XCTAssertEqual(list.count, 47, "默认应从 JSON 加载所有配置的天体")
    }

    func testRealProviderContainsExpectedIds() {
        let provider = RealStarPositionProvider()
        let list = provider.starPositions(date: nightInBeijing, location: beijing)
        let ids = Set(list.map(\.id))

        // 校验边界宿
        XCTAssertTrue(ids.contains("lm_角"))
        XCTAssertTrue(ids.contains("lm_轸"))

        // 校验日月五星
        XCTAssertTrue(ids.contains("sun"))
        XCTAssertTrue(ids.contains("moon"))
        XCTAssertTrue(ids.contains("mercury"))
        XCTAssertTrue(ids.contains("venus"))
        XCTAssertTrue(ids.contains("mars"))
        XCTAssertTrue(ids.contains("jupiter"))
        XCTAssertTrue(ids.contains("saturn"))

        // 校验四余
        XCTAssertTrue(ids.contains("luo_hou"))
        XCTAssertTrue(ids.contains("ji_du"))
        XCTAssertTrue(ids.contains("zi_qi"))
        XCTAssertTrue(ids.contains("yue_bei"))

        // 校验北斗和北极星
        XCTAssertTrue(ids.contains("polaris"))
        XCTAssertTrue(ids.contains("bd_tian_shu"))
    }

    func testSwiftUICoordinateInputConvenienceAPI() {
        let provider = RealStarPositionProvider()
        let input = StarObservationInput(
            date: nightInBeijing,
            coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            altitudeMeters: 0
        )
        let list = provider.starPositions(input: input)
        XCTAssertEqual(list.count, 47)
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

    // MARK: - 4. 月相 (Moon Phase) 计算测试

    func testMoonPhaseCalculation() {
        // 满月例子：北京时间 2024年4月24日 07:49 (UTC: 2024-04-23 23:49)
        var c1 = DateComponents()
        c1.year = 2024; c1.month = 4; c1.day = 23; c1.hour = 23; c1.minute = 49
        let fullMoonDate = Calendar(identifier: .gregorian).date(from: c1)!

        if let fullPhase = calculateMoonPhase(date: fullMoonDate, location: beijing) {
            XCTAssertGreaterThan(fullPhase.percentage, 0.99, "此时应非常接近满月 (1.0)")
            
            // 相位角对于满月来说，理想是 180 度，允许 ±5 度的天文波动误差
            XCTAssertEqual(fullPhase.phaseAngle, 180.0, accuracy: 5.0, "满月相位角应在 180 度附近")
        } else {
            XCTFail("Full moon phase calculation failed")
        }

        // 新月例子：北京时间 2024年5月8日 11:22 (UTC: 2024-05-08 03:22)
        var c2 = DateComponents()
        c2.year = 2024; c2.month = 5; c2.day = 8; c2.hour = 3; c2.minute = 22
        let newMoonDate = Calendar(identifier: .gregorian).date(from: c2)!

        if let newPhase = calculateMoonPhase(date: newMoonDate, location: nil) {
            XCTAssertLessThan(newPhase.percentage, 0.01, "此时应非常接近新月 (0.0)")
            
            // 相位角新月理想值是 0 或 360
            let normalizedPhaseAngle = newPhase.phaseAngle >= 180 ? 360.0 - newPhase.phaseAngle : newPhase.phaseAngle
            XCTAssertEqual(normalizedPhaseAngle, 0.0, accuracy: 6.0, "新月相位角应在 0 度附近，或接近 360")
        } else {
            XCTFail("New moon phase calculation failed")
        }

        // 上弦月（半月）：北京时间 2024年5月15日 19:48 (UTC: 2024-05-15 11:48)
        var c3 = DateComponents()
        c3.year = 2024; c3.month = 5; c3.day = 15; c3.hour = 11; c3.minute = 48
        let firstQuarterDate = Calendar(identifier: .gregorian).date(from: c3)!

        if let waxingPhase = calculateMoonPhase(date: firstQuarterDate, location: nil) {
            XCTAssertEqual(waxingPhase.percentage, 0.5, accuracy: 0.05, "上弦月应被照亮约 50%")
            XCTAssertTrue(waxingPhase.isWaxing, "上弦月时应处于盈长状态 (Waxing)")
        } else {
            XCTFail("Waxing moon phase calculation failed")
        }
    }
}
