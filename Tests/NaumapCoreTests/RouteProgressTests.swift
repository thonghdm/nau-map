import XCTest
@testable import NaumapCore

final class RouteProgressTests: XCTestCase {
    private let routeCoordinates = [
        Coordinate(latitude: 10.7700, longitude: 106.7000),
        Coordinate(latitude: 10.7700, longitude: 106.7050),
        Coordinate(latitude: 10.7750, longitude: 106.7050)
    ]

    func testSnapsToNearestSegmentAndPreservesRouteDistance() {
        let location = Coordinate(latitude: 10.7704, longitude: 106.7025, speed: 10.0)
        let result = PolylineSnapper().snap(location, to: routeCoordinates)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.segmentIndex, 0)
        XCTAssertEqual(result?.coordinate.latitude ?? 0.0, 10.7700, accuracy: 0.00001)
        XCTAssertEqual(result?.distanceFromPolylineMeters ?? 0.0, 44.5, accuracy: 3.0)
    }

    func testAltitudeSeparatesOverpassFromRoadBelow() {
        let road = [
            Coordinate(latitude: 10.7700, longitude: 106.7000, altitude: 2.0),
            Coordinate(latitude: 10.7700, longitude: 106.7050, altitude: 2.0)
        ]
        let upperRoad = Coordinate(latitude: 10.7700, longitude: 106.7025, altitude: 20.0)

        XCTAssertNil(PolylineSnapper(maxAltitudeDifferenceMeters: 5.0).snap(upperRoad, to: road))
    }

    func testRouteProgressReportsRemainingDistanceAndSpeed() {
        let route = RouteData(
            coordinates: routeCoordinates,
            steps: [],
            totalDistanceMeters: routeCoordinates[0].distance(to: routeCoordinates[1]) +
                routeCoordinates[1].distance(to: routeCoordinates[2]),
            estimatedDurationSeconds: 120,
            boundingBox: BoundingBox(
                minLatitude: 10.7700,
                maxLatitude: 10.7750,
                minLongitude: 106.7000,
                maxLongitude: 106.7050
            )
        )
        let location = Coordinate(latitude: 10.7700, longitude: 106.7025, speed: 10.0)
        let progress = RouteProgressTracker().progress(for: location, on: route)

        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.currentSpeedKmh ?? 0.0, 36.0, accuracy: 0.001)
        XCTAssertGreaterThan(progress?.totalDistanceRemainingMeters ?? 0.0, 500.0)
        XCTAssertFalse(progress?.isOffRoute ?? true)
    }

    func testOffRouteRequiresThreeContinuousSeconds() {
        var detector = OffRouteDetector()
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(detector.update(distanceFromRouteMeters: 31, at: start), .trackingSince(start))
        XCTAssertNotEqual(detector.update(distanceFromRouteMeters: 31, at: start.addingTimeInterval(2.9)), .needsReroute)
        XCTAssertEqual(detector.update(distanceFromRouteMeters: 31, at: start.addingTimeInterval(3)), .needsReroute)
        XCTAssertEqual(detector.update(distanceFromRouteMeters: 31, at: start.addingTimeInterval(4)), .needsReroute)
        XCTAssertEqual(detector.update(distanceFromRouteMeters: 0, at: start.addingTimeInterval(5)), .onRoute)
    }
}
