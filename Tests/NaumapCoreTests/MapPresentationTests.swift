import XCTest
@testable import NaumapCore

final class MapPresentationTests: XCTestCase {
    func testNavigationCameraUsesCourseUpAndClampedPitch() {
        let location = Coordinate(latitude: 10.77, longitude: 106.70, bearing: 450.0)
        let camera = MapCameraController().navigationCamera(for: location)

        XCTAssertEqual(camera.mode, .courseUp3D)
        XCTAssertEqual(camera.bearingDegrees, 90.0, accuracy: 0.001)
        XCTAssertEqual(camera.pitchDegrees, 45.0, accuracy: 0.001)
        XCTAssertEqual(camera.zoomLevel, 16.0, accuracy: 0.001)
    }

    func testOverviewCameraUsesNorthUpAndFlatPitch() {
        let location = Coordinate(latitude: 10.77, longitude: 106.70, bearing: 180.0)
        let camera = MapCameraController().overviewCamera(for: location)

        XCTAssertEqual(camera.mode, .northUp2D)
        XCTAssertEqual(camera.bearingDegrees, 0.0, accuracy: 0.001)
        XCTAssertEqual(camera.pitchDegrees, 0.0, accuracy: 0.001)
    }

    func testSpeedBadgeTurnsOverspeedStateOnAndOff() {
        var badge = SpeedLimitBadgeOverlay()

        XCTAssertFalse(badge.update(limitKmh: 50, currentSpeedKmh: 50).isOverspeeding)
        XCTAssertTrue(badge.update(limitKmh: 50, currentSpeedKmh: 51).isOverspeeding)
        XCTAssertFalse(badge.update(limitKmh: nil, currentSpeedKmh: 120).isOverspeeding)
    }
}
