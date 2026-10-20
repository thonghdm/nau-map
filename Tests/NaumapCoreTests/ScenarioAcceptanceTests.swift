import XCTest
@testable import NaumapCore

final class ScenarioAcceptanceTests: XCTestCase {

    func testThuThiemTunnelDeadReckoningStaysOnTunnelPolyline() {
        let tunnel = [
            Coordinate(latitude: 10.7700, longitude: 106.7000, altitude: -5.0),
            Coordinate(latitude: 10.7700, longitude: 106.7050, altitude: -5.0),
            Coordinate(latitude: 10.7700, longitude: 106.7100, altitude: -5.0)
        ]
        let engine = DeadReckoningEngine()

        let result = engine.estimateLocation(
            lastLocation: tunnel[0],
            lastSpeedMps: 20.0,
            lastBearing: 90.0,
            elapsedSeconds: 30.0,
            tunnelPolyline: tunnel
        )

        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.coordinate.latitude, tunnel[0].latitude, accuracy: 0.0001)
        XCTAssertGreaterThan(result.coordinate.longitude, tunnel[0].longitude)
        XCTAssertLessThanOrEqual(result.coordinate.longitude, tunnel[2].longitude)
    }

    func testHangXanhFlyoverDoesNotAlertCameraOnRoadBelow() async throws {
        let vehicle = Coordinate(latitude: 10.8000, longitude: 106.7000, altitude: 20.0)
        let lowerRoadCamera = TrafficPoint(
            id: "hang-xanh-underpass-camera",
            type: .speedCamera,
            coordinate: Coordinate(
                latitude: 10.8000,
                longitude: 106.7005,
                altitude: 2.0
            ),
            targetBearing: 90.0,
            title: "Camera gầm cầu"
        )
        let repository = InMemoryAlertRepository(points: [lowerRoadCamera])
        var engine = SpatialAlertEngine(repository: repository)

        let alerts = try await engine.evaluate(
            location: vehicle,
            vehicleBearing: 90.0,
            speedMps: 15.0
        )

        XCTAssertTrue(alerts.isEmpty)
    }

    func testThangLongParallelRoadDoesNotAlertOppositeBearingSign() async throws {
        let vehicle = Coordinate(latitude: 21.0200, longitude: 105.8000, altitude: 8.0)
        let frontageRoadSign = TrafficPoint(
            id: "thang-long-frontage-road-sign",
            type: .speedLimitSign,
            coordinate: Coordinate(
                latitude: 21.0200,
                longitude: 105.8004,
                altitude: 8.0
            ),
            targetBearing: 270.0,
            bearingTolerance: 20.0,
            speedLimitKmH: 40,
            isParallelRoad: true,
            title: "Biển đường gom"
        )
        let repository = InMemoryAlertRepository(points: [frontageRoadSign])
        var engine = SpatialAlertEngine(repository: repository)

        let alerts = try await engine.evaluate(
            location: vehicle,
            vehicleBearing: 90.0,
            speedMps: 25.0
        )

        XCTAssertTrue(alerts.isEmpty)
    }
}
