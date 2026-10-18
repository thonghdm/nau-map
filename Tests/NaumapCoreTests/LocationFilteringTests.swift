import XCTest
@testable import NaumapCore

final class LocationFilteringTests: XCTestCase {

    func testAccuracyFilterRejectsInaccurateGPS() async throws {
        let actor = LocationServiceActor(maxAccuracyThreshold: 20.0)
        try await actor.startUpdating()

        // 1. Tọa độ chính xác cao (accuracy = 5m <= 20m) -> Chấp nhận
        let accurateCoord = Coordinate(
            latitude: 10.772,
            longitude: 106.698,
            horizontalAccuracy: 5.0
        )
        let accepted = await actor.processRawLocation(accurateCoord)
        XCTAssertTrue(accepted)

        let current = await actor.currentLocation
        XCTAssertNotNil(current)
        XCTAssertEqual(current?.latitude, 10.772)

        // 2. Tọa độ sai số lớn (accuracy = 35m > 20m) -> Từ chối
        let inaccurateCoord = Coordinate(
            latitude: 10.780,
            longitude: 106.700,
            horizontalAccuracy: 35.0
        )
        let rejected = await actor.processRawLocation(inaccurateCoord)
        XCTAssertFalse(rejected)

        // Vị trí hợp lệ gần nhất vẫn là điểm ban đầu
        let currentAfterRejection = await actor.currentLocation
        XCTAssertEqual(currentAfterRejection?.latitude, 10.772)

        // 3. Tọa độ có accuracy âm (GPS invalid signal) -> Từ chối
        let invalidCoord = Coordinate(
            latitude: 10.790,
            longitude: 106.710,
            horizontalAccuracy: -1.0
        )
        let rejectedNegative = await actor.processRawLocation(invalidCoord)
        XCTAssertFalse(rejectedNegative)
    }

    func testDeadReckoningTickTriggeredOnGPSTimeout() async throws {
        let actor = LocationServiceActor(
            maxAccuracyThreshold: 20.0,
            gpsLossTimeoutSeconds: 2.0
        )
        try await actor.startUpdating()

        let baseTime = Date()
        let initialCoord = Coordinate(
            latitude: 10.770,
            longitude: 106.700,
            bearing: 90.0,
            speed: 15.0, // 15 m/s
            horizontalAccuracy: 5.0,
            timestamp: baseTime
        )
        await actor.processRawLocation(initialCoord)

        // Thử tick ngay sau 1.0s (chưa quá timeout 2.0s) -> Không kích hoạt
        let tickEarly = await actor.performDeadReckoningTick(currentTime: baseTime.addingTimeInterval(1.0))
        XCTAssertNil(tickEarly)

        // Thử tick sau 5.0s (đã mất GPS 5s > 2s) -> Kích hoạt Dead-Reckoning
        let tickAfterTimeout = await actor.performDeadReckoningTick(currentTime: baseTime.addingTimeInterval(5.0))
        XCTAssertNotNil(tickAfterTimeout)

        if let (estimatedCoord, confidence) = tickAfterTimeout {
            XCTAssertEqual(confidence, .high)
            XCTAssertGreaterThan(estimatedCoord.longitude, initialCoord.longitude)
        }
    }
}
