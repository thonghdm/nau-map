import XCTest
@testable import NaumapCore

final class CarPlayCoordinatorTests: XCTestCase {
    func testConnectionLifecycleResetsPresentationStateOnDisconnect() async {
        let coordinator = CarPlayNavigationCoordinator()

        await coordinator.beginConnecting()
        var snapshot = await coordinator.snapshot
        XCTAssertEqual(snapshot.connectionState, .connecting)
        await coordinator.connect()
        await coordinator.setMapButtons([.zoomIn, .compass])
        snapshot = await coordinator.snapshot
        XCTAssertEqual(snapshot.connectionState, .connected)
        XCTAssertEqual(snapshot.mapButtons, [.zoomIn, .compass])

        await coordinator.disconnect()
        snapshot = await coordinator.snapshot
        XCTAssertEqual(snapshot, CarPlayNavigationSnapshot())
    }

    func testNavigationAndAlertUpdatesProduceCarPlaySnapshot() async {
        let coordinator = CarPlayNavigationCoordinator()
        let location = Coordinate(latitude: 10.77, longitude: 106.70, speed: 10.0)
        let step = ManeuverStep(
            instruction: "Rẽ phải",
            type: .turnRight,
            coordinate: location,
            distanceToNextStepMeters: 100,
            remainingDurationSeconds: 30
        )
        let progress = RouteProgress(
            currentCoordinate: location,
            currentStepIndex: 0,
            currentStep: step,
            distanceToNextStepMeters: 100,
            totalDistanceRemainingMeters: 1000,
            totalDurationRemainingSeconds: 100,
            currentSpeedKmh: 36
        )
        let point = TrafficPoint(
            id: "camera",
            type: .speedCamera,
            coordinate: location,
            title: "Camera tốc độ"
        )
        let alert = AlertEvent(
            trafficPoint: point,
            distanceMeters: 100,
            estimatedTimeToArrivalSeconds: 10,
            currentSpeedKmh: 36,
            severity: .warning,
            spokenMessage: "Camera phía trước",
            visualBannerText: "Camera 100m"
        )

        await coordinator.updateNavigation(progress: progress)
        await coordinator.present(alert: alert)
        let snapshot = await coordinator.snapshot

        XCTAssertEqual(snapshot.maneuver, step)
        XCTAssertEqual(snapshot.travelEstimates, CarPlayTravelEstimates(distanceRemainingMeters: 1000, timeRemainingSeconds: 100))
        XCTAssertEqual(snapshot.activeAlert, alert)
    }
}
