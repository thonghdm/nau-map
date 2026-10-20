import Foundation

public enum OffRouteStatus: Equatable, Sendable {
    case onRoute
    case trackingSince(Date)
    case needsReroute
}

/// Chỉ phát hiện lệch đường sau khi sai số vượt ngưỡng liên tục trong một khoảng thời gian.
public struct OffRouteDetector: Sendable {
    public let thresholdMeters: Double
    public let requiredDuration: TimeInterval
    private var exceededSince: Date?
    private var rerouteEmitted = false

    public init(thresholdMeters: Double = 30.0, requiredDuration: TimeInterval = 3.0) {
        self.thresholdMeters = thresholdMeters
        self.requiredDuration = requiredDuration
    }

    public mutating func update(distanceFromRouteMeters: Double, at timestamp: Date) -> OffRouteStatus {
        guard distanceFromRouteMeters > thresholdMeters else {
            exceededSince = nil
            rerouteEmitted = false
            return .onRoute
        }

        if exceededSince == nil {
            exceededSince = timestamp
        }
        guard let start = exceededSince else { return .trackingSince(timestamp) }
        if !rerouteEmitted && timestamp.timeIntervalSince(start) >= requiredDuration {
            rerouteEmitted = true
            return .needsReroute
        }
        return rerouteEmitted ? .needsReroute : .trackingSince(start)
    }
}
