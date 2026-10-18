import XCTest
@testable import NaumapCore

final class GPXPlaybackTests: XCTestCase {

    func testStepByStepPlayback() {
        let p1 = Coordinate(latitude: 10.771, longitude: 106.691)
        let p2 = Coordinate(latitude: 10.772, longitude: 106.692)
        let p3 = Coordinate(latitude: 10.773, longitude: 106.693)

        let service = GPXPlaybackService(waypoints: [p1, p2, p3])

        XCTAssertEqual(service.stepNext()?.latitude, p1.latitude)
        XCTAssertEqual(service.stepNext()?.latitude, p2.latitude)
        XCTAssertEqual(service.stepNext()?.latitude, p3.latitude)
        // Hết danh sách -> trả về nil
        XCTAssertNil(service.stepNext())
    }

    func testSimulatedGPSLossRange() {
        let points = (0..<6).map { i in
            Coordinate(latitude: 10.770 + Double(i) * 0.001, longitude: 106.690)
        }

        // Giả lập đoạn hầm mất GPS từ điểm thứ 2 đến điểm thứ 4 (index 2...4)
        let service = GPXPlaybackService(
            waypoints: points,
            gpsLossIndexRange: 2...4
        )

        // Điểm 0, 1 bình thường
        XCTAssertNotNil(service.stepNext()) // index 0
        XCTAssertNotNil(service.stepNext()) // index 1

        // Điểm 2, 3, 4 mất sóng -> trả về nil
        XCTAssertNil(service.stepNext()) // index 2
        XCTAssertNil(service.stepNext()) // index 3
        XCTAssertNil(service.stepNext()) // index 4

        // Điểm 5 ra khỏi hầm -> có lại GPS
        let exitPoint = service.stepNext()
        XCTAssertNotNil(exitPoint)
        XCTAssertEqual(exitPoint?.latitude, points[5].latitude)
    }
}
