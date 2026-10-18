import Foundation

/// Mức độ tin cậy của ước lượng vị trí khi xe mất GPS (ví dụ khi đi qua hầm)
public enum DeadReckoningConfidence: String, Codable, Sendable {
    case high = "high"         // Dưới 15 giây mất GPS: Vị trí ước lượng rất chuẩn
    case low = "low"           // Từ 15 - 45 giây mất GPS: Cần hiển thị cảnh báo cho tài xế
    case signalLost = "signal_lost" // Trên 45 giây mất GPS: Ngừng dự phóng để tránh rủi ro
}

/// Tiến trình di chuyển dọc theo lộ trình dẫn đường
public struct RouteProgress: Hashable, Codable, Sendable {
    public let currentCoordinate: Coordinate
    public let currentStepIndex: Int
    public let currentStep: ManeuverStep?
    public let distanceToNextStepMeters: Double
    public let totalDistanceRemainingMeters: Double
    public let totalDurationRemainingSeconds: TimeInterval
    public let currentSpeedKmh: Double
    public let isOffRoute: Bool

    public init(
        currentCoordinate: Coordinate,
        currentStepIndex: Int,
        currentStep: ManeuverStep?,
        distanceToNextStepMeters: Double,
        totalDistanceRemainingMeters: Double,
        totalDurationRemainingSeconds: TimeInterval,
        currentSpeedKmh: Double,
        isOffRoute: Bool = false
    ) {
        self.currentCoordinate = currentCoordinate
        self.currentStepIndex = currentStepIndex
        self.currentStep = currentStep
        self.distanceToNextStepMeters = distanceToNextStepMeters
        self.totalDistanceRemainingMeters = totalDistanceRemainingMeters
        self.totalDurationRemainingSeconds = totalDurationRemainingSeconds
        self.currentSpeedKmh = currentSpeedKmh
        self.isOffRoute = isOffRoute
    }
}

/// Trạng thái cốt lõi của Navigation State Machine
public enum NavigationState: Sendable, Equatable {
    case idle
    case freeDrive(currentLocation: Coordinate, headingConfidence: Double, speedKmh: Double)
    case navigating(progress: RouteProgress, deadReckoningConfidence: DeadReckoningConfidence)
}

/// Các sự kiện hệ thống phát ra từ Core Engine cho UI/CarPlay Layer
public enum NavigationEvent: Sendable {
    case stateChanged(NavigationState)
    case alertTriggered(AlertEvent)
    case speedLimitChanged(currentLimitKmh: Int?)
    case offRouteDetected(lastKnownLocation: Coordinate)
    case tunnelEntered(entrance: TrafficPoint)
    case tunnelExited
}
