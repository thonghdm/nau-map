import XCTest
@testable import NaumapCore

final class SpatialAlertTests: XCTestCase {
    func testRepositoryFiltersCandidatesToForwardCorridor() async throws {
        let origin = Coordinate(latitude: 10.7700, longitude: 106.7000)
        let forward = origin.destination(distanceMeters: 100, bearingDegrees: 90)
        let behind = origin.destination(distanceMeters: 100, bearingDegrees: 270)
        let repository = InMemoryAlertRepository(points: [
            TrafficPoint(id: "front", type: .speedCamera, coordinate: forward, title: "Camera trước"),
            TrafficPoint(id: "behind", type: .speedCamera, coordinate: behind, title: "Camera sau")
        ])
        let corridor = GeoCorridor(origin: origin, headingDegrees: 90, lookaheadDistanceMeters: 200)

        let candidates = try await repository.fetchCandidates(in: corridor)
        XCTAssertEqual(candidates.map(\.id), ["front"])
    }

    func testEngineFiltersBearingAndDeduplicates() async throws {
        let origin = Coordinate(latitude: 10.7700, longitude: 106.7000)
        let point = TrafficPoint(
            id: "camera",
            type: .speedCamera,
            coordinate: origin.destination(distanceMeters: 100, bearingDegrees: 90),
            targetBearing: 90,
            title: "Camera tốc độ"
        )
        let repository = InMemoryAlertRepository(points: [point])
        var engine = SpatialAlertEngine(repository: repository)

        let first = try await engine.evaluate(location: origin, vehicleBearing: 90, speedMps: 10)
        let second = try await engine.evaluate(location: origin, vehicleBearing: 90, speedMps: 10)

        XCTAssertEqual(first.count, 1)
        XCTAssertTrue(second.isEmpty)
        XCTAssertEqual(first[0].severity, .warning)
    }
}
