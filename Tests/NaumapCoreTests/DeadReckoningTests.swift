import XCTest
@testable import NaumapCore

final class DeadReckoningTests: XCTestCase {

    var engine: DeadReckoningEngine!

    override func setUp() {
        super.setUp()
        engine = DeadReckoningEngine(
            decayFactor: 0.98,
            highConfidenceTimeout: 15.0,
            signalLostTimeout: 45.0
        )
    }

    func testConfidenceTransitions() {
        // Dưới 15s -> High confidence
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 0.0), .high)
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 14.9), .high)

        // Từ 15s đến 45s -> Low confidence
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 15.0), .low)
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 30.0), .low)
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 44.9), .low)

        // Sau 45s -> Signal lost
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 45.0), .signalLost)
        XCTAssertEqual(engine.evaluateConfidence(elapsedSeconds: 60.0), .signalLost)
    }

    func testDistanceDecayFormula() {
        let speed = 20.0 // 20 m/s (~72 km/h)
        let elapsed = 10.0 // 10 giây

        let estimatedDistance = engine.estimateDistanceTraveled(
            lastKnownSpeedMps: speed,
            elapsedSeconds: elapsed
        )

        // Nếu chuyển động đều không suy giảm: S = 20 * 10 = 200m
        // Khi có suy giảm (0.98^10 ≈ 0.817): S = 20 * 10 * 0.817 ≈ 163.4m
        XCTAssertLessThan(estimatedDistance, 200.0)
        XCTAssertGreaterThan(estimatedDistance, 150.0)
    }

    func testProjectionAlongTunnelPolyline() {
        // Mô phỏng hầm Thủ Thiêm: Đoạn đường thẳng từ Tây sang Đông
        let entrance = Coordinate(latitude: 10.7700, longitude: 106.7000)
        let midPoint = Coordinate(latitude: 10.7700, longitude: 106.7050)
        let exitPoint = Coordinate(latitude: 10.7700, longitude: 106.7100)
        let tunnelPolyline = [entrance, midPoint, exitPoint]

        let lastSpeed = 15.0 // 15 m/s
        let elapsed = 10.0 // 10 giây mất GPS

        let (projected, confidence) = engine.estimateLocation(
            lastLocation: entrance,
            lastSpeedMps: lastSpeed,
            lastBearing: 90.0, // Hướng Đông
            elapsedSeconds: elapsed,
            tunnelPolyline: tunnelPolyline
        )

        XCTAssertEqual(confidence, .high)
        // Vĩ độ phải giữ nguyên 10.7700 (bám sát tim hầm, không lệch sang sông)
        XCTAssertEqual(projected.latitude, 10.7700, accuracy: 0.0001)
        // Kinh độ phải tăng dần về phía Đông
        XCTAssertGreaterThan(projected.longitude, entrance.longitude)
    }

    func testSignalLostStopsProjection() {
        let startLocation = Coordinate(latitude: 10.7700, longitude: 106.7000)
        let elapsed = 50.0 // 50 giây (> 45s timeout)

        let (resultCoord, confidence) = engine.estimateLocation(
            lastLocation: startLocation,
            lastSpeedMps: 20.0,
            lastBearing: 90.0,
            elapsedSeconds: elapsed
        )

        XCTAssertEqual(confidence, .signalLost)
        // Khi mất sóng quá hạn, không được dự phóng thêm mà khóa vị trí tại điểm an toàn
        XCTAssertEqual(resultCoord.latitude, startLocation.latitude)
        XCTAssertEqual(resultCoord.longitude, startLocation.longitude)
    }
}
