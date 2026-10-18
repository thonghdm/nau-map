import XCTest
@testable import NaumapCore

final class CoordinateTests: XCTestCase {

    func testHaversineDistanceBetweenKnownLocations() {
        // Chợ Bến Thành (10.7720, 106.6983)
        let benThanh = Coordinate(latitude: 10.7720, longitude: 106.6983)
        // Nhà thờ Đức Bà Sài Gòn (10.7798, 106.6990)
        let ducBa = Coordinate(latitude: 10.7798, longitude: 106.6990)

        let distance = benThanh.distance(to: ducBa)

        // Cự ly thực tế khoảng 870 mét, kiểm tra sai số dưới 15 mét
        XCTAssertGreaterThan(distance, 850.0)
        XCTAssertLessThan(distance, 900.0)
    }

    func testBearingCalculationNorthward() {
        // Điểm A ở phía Nam, Điểm B thẳng về phía Bắc trên cùng kinh tuyến
        let start = Coordinate(latitude: 10.0, longitude: 106.0)
        let northPoint = Coordinate(latitude: 11.0, longitude: 106.0)

        let bearing = start.bearing(to: northPoint)
        // Hướng Bắc tương ứng 0° (sai số < 0.1°)
        XCTAssertEqual(bearing, 0.0, accuracy: 0.1)
    }

    func testBearingCalculationEastward() {
        // Điểm A ở xích đạo, Điểm B thẳng về phía Đông trên cùng vĩ tuyến
        let start = Coordinate(latitude: 0.0, longitude: 106.0)
        let eastPoint = Coordinate(latitude: 0.0, longitude: 107.0)

        let bearing = start.bearing(to: eastPoint)
        // Hướng Đông tương ứng 90° (sai số < 0.1°)
        XCTAssertEqual(bearing, 90.0, accuracy: 0.1)
    }

    func testDestinationProjection() {
        let start = Coordinate(latitude: 10.7720, longitude: 106.6983)
        let targetDistance = 1000.0 // 1 km
        let targetBearing = 90.0    // Hướng Đông

        let destination = start.destination(distanceMeters: targetDistance, bearingDegrees: targetBearing)
        let calculatedDistance = start.distance(to: destination)

        // Khoảng cách đo lại phải xấp xỉ 1000m (sai số dưới 1m)
        XCTAssertEqual(calculatedDistance, targetDistance, accuracy: 1.0)
    }
}
