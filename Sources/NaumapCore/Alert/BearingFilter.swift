import Foundation

public struct BearingFilter: Sendable {
    public let defaultToleranceDegrees: Double

    public init(defaultToleranceDegrees: Double = 30.0) {
        self.defaultToleranceDegrees = defaultToleranceDegrees
    }

    public func matches(point: TrafficPoint, vehicleBearing: Double) -> Bool {
        point.matchesBearing(vehicleBearing)
    }
}
