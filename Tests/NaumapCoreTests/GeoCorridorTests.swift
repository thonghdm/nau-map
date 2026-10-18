import XCTest
@testable import NaumapCore

final class GeoCorridorTests: XCTestCase {

    func testCorridorBoundingBoxContainsFrontPoints() {
        let origin = Coordinate(latitude: 10.7720, longitude: 106.6980)
        let heading = 90.0 // Đi về hướng Đông
        let lookaheadDistance = 500.0 // 500m

        let corridor = GeoCorridor(
            origin: origin,
            headingDegrees: heading,
            lookaheadDistanceMeters: lookaheadDistance,
            corridorWidthMeters: 60.0
        )

        // Điểm nằm thẳng phía trước 250m phải nằm trong BoundingBox
        let frontPoint = origin.destination(distanceMeters: 250.0, bearingDegrees: 90.0)
        XCTAssertTrue(corridor.boundingBox.contains(frontPoint))

        // Điểm nằm cách xe 20m về bên phải phải nằm trong BoundingBox
        let rightSidePoint = origin.destination(distanceMeters: 20.0, bearingDegrees: 180.0)
        XCTAssertTrue(corridor.boundingBox.contains(rightSidePoint))

        // Điểm nằm ở phía sau đuôi xe 100m KHÔNG được nằm trong BoundingBox
        let rearPoint = origin.destination(distanceMeters: 100.0, bearingDegrees: 270.0)
        XCTAssertFalse(corridor.boundingBox.contains(rearPoint))
    }
}
