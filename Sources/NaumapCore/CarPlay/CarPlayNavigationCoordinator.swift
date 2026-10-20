import Foundation

public enum CarPlayConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
}

public enum CarPlayMapButton: String, CaseIterable, Codable, Sendable {
    case zoomIn
    case zoomOut
    case pan
    case compass
    case routeOverview
}

public struct CarPlayTravelEstimates: Hashable, Codable, Sendable {
    public let distanceRemainingMeters: Double
    public let timeRemainingSeconds: TimeInterval

    public init(distanceRemainingMeters: Double, timeRemainingSeconds: TimeInterval) {
        self.distanceRemainingMeters = max(0.0, distanceRemainingMeters)
        self.timeRemainingSeconds = max(0.0, timeRemainingSeconds)
    }
}

public struct CarPlayNavigationSnapshot: Equatable, Sendable {
    public var connectionState: CarPlayConnectionState
    public var mapButtons: [CarPlayMapButton]
    public var panInterfaceVisible: Bool
    public var maneuver: ManeuverStep?
    public var travelEstimates: CarPlayTravelEstimates?
    public var activeAlert: AlertEvent?

    public init(
        connectionState: CarPlayConnectionState = .disconnected,
        mapButtons: [CarPlayMapButton] = [],
        panInterfaceVisible: Bool = false,
        maneuver: ManeuverStep? = nil,
        travelEstimates: CarPlayTravelEstimates? = nil,
        activeAlert: AlertEvent? = nil
    ) {
        self.connectionState = connectionState
        self.mapButtons = mapButtons
        self.panInterfaceVisible = panInterfaceVisible
        self.maneuver = maneuver
        self.travelEstimates = travelEstimates
        self.activeAlert = activeAlert
    }
}

/// Core state coordinator consumed by a platform-specific CPTemplate adapter.
public actor CarPlayNavigationCoordinator {
    public private(set) var snapshot: CarPlayNavigationSnapshot
    private var continuation: AsyncStream<CarPlayNavigationSnapshot>.Continuation?
    public nonisolated let snapshotStream: AsyncStream<CarPlayNavigationSnapshot>

    public init() {
        var continuation: AsyncStream<CarPlayNavigationSnapshot>.Continuation?
        snapshotStream = AsyncStream { continuation = $0 }
        self.continuation = continuation
        snapshot = CarPlayNavigationSnapshot()
    }

    public func connect() {
        update { $0.connectionState = .connected }
    }

    public func beginConnecting() {
        update { $0.connectionState = .connecting }
    }

    public func disconnect() {
        update {
            $0 = CarPlayNavigationSnapshot(connectionState: .disconnected)
        }
    }

    public func setMapButtons(_ buttons: [CarPlayMapButton]) {
        update { $0.mapButtons = buttons }
    }

    public func setPanInterfaceVisible(_ visible: Bool) {
        update { $0.panInterfaceVisible = visible }
    }

    public func updateNavigation(progress: RouteProgress) {
        let estimates = CarPlayTravelEstimates(
            distanceRemainingMeters: progress.totalDistanceRemainingMeters,
            timeRemainingSeconds: progress.totalDurationRemainingSeconds
        )
        update {
            $0.maneuver = progress.currentStep
            $0.travelEstimates = estimates
        }
    }

    public func present(alert: AlertEvent) {
        update { $0.activeAlert = alert }
    }

    public func dismissAlert() {
        update { $0.activeAlert = nil }
    }

    private func update(_ mutation: (inout CarPlayNavigationSnapshot) -> Void) {
        var next = snapshot
        mutation(&next)
        snapshot = next
        continuation?.yield(next)
    }

    deinit {
        continuation?.finish()
    }
}
