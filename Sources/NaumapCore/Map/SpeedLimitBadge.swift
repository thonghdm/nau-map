import Foundation

public struct SpeedLimitBadgeState: Equatable, Codable, Sendable {
    public let limitKmh: Int?
    public let currentSpeedKmh: Double
    public let isOverspeeding: Bool

    public init(limitKmh: Int?, currentSpeedKmh: Double, overspeedToleranceKmh: Double = 0.0) {
        self.limitKmh = limitKmh
        self.currentSpeedKmh = max(0.0, currentSpeedKmh)
        self.isOverspeeding = limitKmh.map {
            currentSpeedKmh > Double($0) + max(0.0, overspeedToleranceKmh)
        } ?? false
    }
}

public struct SpeedLimitBadgeOverlay: Sendable {
    public let overspeedToleranceKmh: Double
    public private(set) var state: SpeedLimitBadgeState

    public init(overspeedToleranceKmh: Double = 0.0) {
        self.overspeedToleranceKmh = max(0.0, overspeedToleranceKmh)
        state = SpeedLimitBadgeState(limitKmh: nil, currentSpeedKmh: 0.0)
    }

    @discardableResult
    public mutating func update(limitKmh: Int?, currentSpeedKmh: Double) -> SpeedLimitBadgeState {
        state = SpeedLimitBadgeState(
            limitKmh: limitKmh,
            currentSpeedKmh: currentSpeedKmh,
            overspeedToleranceKmh: overspeedToleranceKmh
        )
        return state
    }
}
