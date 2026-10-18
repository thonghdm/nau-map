import XCTest
@testable import NaumapCore

final class TrafficPointTests: XCTestCase {

    func testBearingMatchingWithinTolerance() {
        let camera = TrafficPoint(
            id: "CAM-01",
            type: .speedCamera,
            coordinate: Coordinate(latitude: 10.772, longitude: 106.698),
            targetBearing: 90.0, // Hướng Đông
            bearingTolerance: 30.0,
            speedLimitKmH: 60,
            title: "Camera Tốc Độ Võ Văn Kiệt"
        )

        // Xe chạy cùng hướng 90° -> Khớp
        XCTAssertTrue(camera.matchesBearing(90.0))

        // Xe chạy lệch 25° (115°) -> Nằm trong giới hạn ±30° -> Khớp
        XCTAssertTrue(camera.matchesBearing(115.0))

        // Xe chạy lệch -25° (65°) -> Nằm trong giới hạn ±30° -> Khớp
        XCTAssertTrue(camera.matchesBearing(65.0))

        // Xe chạy lệch 45° (135°) -> Vượt quá ±30° -> Không khớp
        XCTAssertFalse(camera.matchesBearing(135.0))

        // Xe chạy hướng ngược lại 270° -> Không khớp
        XCTAssertFalse(camera.matchesBearing(270.0))
    }

    func testBearingMatchingAroundZeroDegreeBoundary() {
        // Camera hướng Bắc (5°)
        let northCamera = TrafficPoint(
            id: "CAM-NORTH",
            type: .redLightCamera,
            coordinate: Coordinate(latitude: 10.772, longitude: 106.698),
            targetBearing: 5.0,
            bearingTolerance: 30.0,
            title: "Camera Phạt Nguội Ngã Tư"
        )

        // Xe chạy hướng 350° (lệch 15° qua mốc 360°/0°) -> Phải khớp
        XCTAssertTrue(northCamera.matchesBearing(350.0))

        // Xe chạy hướng 320° (lệch 45° qua mốc 0°) -> Không khớp
        XCTAssertFalse(northCamera.matchesBearing(320.0))
    }

    func testOmniDirectionalPointAlwaysMatches() {
        // Điểm cảnh báo không giới hạn hướng (targetBearing = nil)
        let alert = TrafficPoint(
            id: "ZONE-01",
            type: .accidentBlackspot,
            coordinate: Coordinate(latitude: 10.772, longitude: 106.698),
            targetBearing: nil,
            title: "Điểm đen tai nạn"
        )

        XCTAssertTrue(alert.matchesBearing(0.0))
        XCTAssertTrue(alert.matchesBearing(180.0))
        XCTAssertTrue(alert.matchesBearing(359.0))
    }
}
