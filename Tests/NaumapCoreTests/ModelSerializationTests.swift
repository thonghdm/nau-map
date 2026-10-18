import XCTest
@testable import NaumapCore

final class ModelSerializationTests: XCTestCase {

    func testTrafficPointJSONRoundTrip() throws {
        let point = TrafficPoint(
            id: "TP-VN-001",
            type: .speedCamera,
            coordinate: Coordinate(latitude: 10.7725, longitude: 106.6981, altitude: 12.5),
            targetBearing: 180.0,
            bearingTolerance: 30.0,
            speedLimitKmH: 50,
            isOverpassOrUpperLevel: false,
            isParallelRoad: false,
            title: "Camera Tốc Độ",
            subtitle: "Đoạn qua Hầm Thủ Thiêm",
            epochId: 1002
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(point)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TrafficPoint.self, from: data)

        XCTAssertEqual(decoded.id, point.id)
        XCTAssertEqual(decoded.type, point.type)
        XCTAssertEqual(decoded.speedLimitKmH, 50)
        XCTAssertEqual(decoded.coordinate.latitude, point.coordinate.latitude, accuracy: 0.00001)
        XCTAssertEqual(decoded.coordinate.longitude, point.coordinate.longitude, accuracy: 0.00001)
    }

    func testAlertEventJSONRoundTrip() throws {
        let point = TrafficPoint(
            id: "TP-002",
            type: .redLightCamera,
            coordinate: Coordinate(latitude: 10.8000, longitude: 106.7000),
            title: "Camera Phạt Nguội"
        )

        let alert = AlertEvent(
            id: "EVT-999",
            trafficPoint: point,
            distanceMeters: 280.0,
            estimatedTimeToArrivalSeconds: 12.0,
            currentSpeedKmh: 55.0,
            severity: .warning,
            isAmbiguousRoute: false,
            spokenMessage: "Chú ý, camera phạt nguội phía trước 300 mét",
            visualBannerText: "Camera phạt nguội 300m",
            requiresAudioChime: true
        )

        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(AlertEvent.self, from: data)

        XCTAssertEqual(decoded.id, "EVT-999")
        XCTAssertEqual(decoded.severity, .warning)
        XCTAssertEqual(decoded.spokenMessage, alert.spokenMessage)
    }
}
