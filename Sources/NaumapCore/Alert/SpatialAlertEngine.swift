import Foundation

/// Kết hợp corridor query, bearing filter và deduplication thành một luồng candidate alert.
public struct SpatialAlertEngine: Sendable {
    public let repository: any AlertRepositoryProtocol
    public let bearingFilter: BearingFilter
    public var deduplicator: AlertDeduplicator

    public init(
        repository: any AlertRepositoryProtocol,
        bearingFilter: BearingFilter = BearingFilter(),
        deduplicator: AlertDeduplicator = AlertDeduplicator()
    ) {
        self.repository = repository
        self.bearingFilter = bearingFilter
        self.deduplicator = deduplicator
    }

    public mutating func evaluate(
        location: Coordinate,
        vehicleBearing: Double,
        speedMps: Double,
        lookaheadSeconds: TimeInterval = 12.0,
        corridorWidthMeters: Double = 60.0
    ) async throws -> [AlertEvent] {
        let lookaheadDistance = max(0.0, speedMps) * lookaheadSeconds
        let corridor = GeoCorridor(
            origin: location,
            headingDegrees: vehicleBearing,
            lookaheadDistanceMeters: lookaheadDistance,
            corridorWidthMeters: corridorWidthMeters
        )
        let candidates = try await repository.fetchCandidates(in: corridor)

        return candidates.compactMap { point in
            guard bearingFilter.matches(point: point, vehicleBearing: vehicleBearing),
                  deduplicator.shouldEmit(point: point, vehicleBearing: vehicleBearing) else {
                return nil
            }

            let distance = location.distance(to: point.coordinate)
            let eta = speedMps > 0.1 ? distance / speedMps : .infinity
            let severity: AlertSeverity = point.type == .speedCamera || point.type == .redLightCamera
                ? .warning
                : .caution
            let distanceText = "\(Int(distance.rounded()))m"
            return AlertEvent(
                trafficPoint: point,
                distanceMeters: distance,
                estimatedTimeToArrivalSeconds: eta,
                currentSpeedKmh: max(0.0, speedMps) * 3.6,
                severity: severity,
                spokenMessage: "\(point.title) phía trước \(distanceText)",
                visualBannerText: "\(point.title) \(distanceText)"
            )
        }
    }
}
