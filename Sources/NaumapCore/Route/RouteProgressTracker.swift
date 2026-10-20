import Foundation

/// Tính tiến trình tuyến đường từ vị trí đã được map-match.
public struct RouteProgressTracker: Sendable {
    public let snapper: PolylineSnapper
    public let offRouteThresholdMeters: Double

    public init(
        snapper: PolylineSnapper = PolylineSnapper(),
        offRouteThresholdMeters: Double = 30.0
    ) {
        self.snapper = snapper
        self.offRouteThresholdMeters = offRouteThresholdMeters
    }

    public func progress(
        for location: Coordinate,
        on route: RouteData
    ) -> RouteProgress? {
        guard let snap = snapper.snap(location, to: route.coordinates) else { return nil }

        let nextStepIndex = nextStepIndex(
            after: snap.distanceAlongRouteMeters,
            steps: route.steps,
            routeCoordinates: route.coordinates
        )
        let step = route.steps.indices.contains(nextStepIndex) ? route.steps[nextStepIndex] : nil
        let distanceToStep = step.map {
            max(0.0, (snapper.distanceAlongRoute(to: $0.coordinate, on: route.coordinates) ?? snap.distanceAlongRouteMeters) - snap.distanceAlongRouteMeters)
        } ?? 0.0
        let remaining = max(0.0, route.totalDistanceMeters - snap.distanceAlongRouteMeters)
        let speedMps = max(0.0, location.speed ?? 0.0)
        let duration = speedMps > 0.1
            ? remaining / speedMps
            : route.estimatedDurationSeconds * (route.totalDistanceMeters > 0 ? remaining / route.totalDistanceMeters : 0.0)

        return RouteProgress(
            currentCoordinate: snap.coordinate,
            currentStepIndex: nextStepIndex,
            currentStep: step,
            distanceToNextStepMeters: distanceToStep,
            totalDistanceRemainingMeters: remaining,
            totalDurationRemainingSeconds: duration,
            currentSpeedKmh: speedMps * 3.6,
            isOffRoute: snap.distanceFromPolylineMeters > offRouteThresholdMeters
        )
    }

    private func nextStepIndex(
        after distance: Double,
        steps: [ManeuverStep],
        routeCoordinates: [Coordinate]
    ) -> Int {
        for (index, step) in steps.enumerated() {
            let stepDistance = snapper.distanceAlongRoute(to: step.coordinate, on: routeCoordinates) ?? 0.0
            if stepDistance > distance {
                return index
            }
        }
        return steps.count
    }
}
