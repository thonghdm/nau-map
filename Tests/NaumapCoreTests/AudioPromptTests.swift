import XCTest
@testable import NaumapCore

final class AudioPromptTests: XCTestCase {
    func testCriticalPromptPreemptsLowerPriority() {
        var queue = VoicePromptQueue()
        _ = queue.enqueue(text: "Thông tin", priority: .info)
        _ = queue.enqueue(text: "Cảnh báo", priority: .warning)
        _ = queue.enqueue(text: "Khẩn cấp", priority: .critical)

        XCTAssertEqual(queue.dequeue()?.text, "Khẩn cấp")
        XCTAssertEqual(queue.dequeue()?.text, "Cảnh báo")
        XCTAssertEqual(queue.dequeue()?.text, "Thông tin")
        XCTAssertTrue(queue.isEmpty)
    }

    func testSamePriorityPreservesFIFOOrder() {
        var queue = VoicePromptQueue()
        _ = queue.enqueue(text: "Một", priority: .warning)
        _ = queue.enqueue(text: "Hai", priority: .warning)

        XCTAssertEqual(queue.dequeue()?.text, "Một")
        XCTAssertEqual(queue.dequeue()?.text, "Hai")
    }

    func testDuckingCoordinatorRestoresAfterPrompt() {
        var coordinator = AudioPromptCoordinator(duckedVolume: 0.3)

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(coordinator.startedPrompt(), .ducking)
        XCTAssertEqual(coordinator.finishedPrompt(), .restoring)
        XCTAssertEqual(coordinator.restored(), .idle)
        XCTAssertEqual(coordinator.duckedVolume, 0.3, accuracy: 0.001)
    }

    func testAlertMapsToPromptPriorityAndText() {
        let point = TrafficPoint(
            id: "camera",
            type: .speedCamera,
            coordinate: Coordinate(latitude: 10.77, longitude: 106.70),
            title: "Camera tốc độ"
        )
        let alert = AlertEvent(
            trafficPoint: point,
            distanceMeters: 100,
            estimatedTimeToArrivalSeconds: 10,
            currentSpeedKmh: 36,
            severity: .critical,
            spokenMessage: "Giảm tốc độ",
            visualBannerText: "Camera 100m"
        )

        let prompt = VoicePrompt(alert: alert)
        XCTAssertEqual(prompt.id, alert.id)
        XCTAssertEqual(prompt.text, "Giảm tốc độ")
        XCTAssertEqual(prompt.priority, .critical)
        XCTAssertTrue(prompt.requiresChime)
    }
}
