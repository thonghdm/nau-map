import Foundation

/// Kết quả map-matching một vị trí lên đoạn gần nhất của polyline.
public struct PolylineSnapResult: Hashable, Codable, Sendable {
    public let coordinate: Coordinate
    public let segmentIndex: Int
    public let fraction: Double
    public let distanceFromPolylineMeters: Double
    public let distanceAlongRouteMeters: Double

    public init(
        coordinate: Coordinate,
        segmentIndex: Int,
        fraction: Double,
        distanceFromPolylineMeters: Double,
        distanceAlongRouteMeters: Double
    ) {
        self.coordinate = coordinate
        self.segmentIndex = segmentIndex
        self.fraction = fraction
        self.distanceFromPolylineMeters = distanceFromPolylineMeters
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
    }
}

/// Chiếu vị trí GPS lên đoạn polyline gần nhất bằng phép chiếu phẳng cục bộ.
public struct PolylineSnapper: Sendable {
    public let maxAltitudeDifferenceMeters: Double

    public init(maxAltitudeDifferenceMeters: Double = 10.0) {
        self.maxAltitudeDifferenceMeters = maxAltitudeDifferenceMeters
    }

    public func snap(
        _ location: Coordinate,
        to polyline: [Coordinate]
    ) -> PolylineSnapResult? {
        guard polyline.count >= 2 else { return nil }

        var cumulativeDistance = 0.0
        var best: PolylineSnapResult?

        for index in 0..<(polyline.count - 1) {
            let start = polyline[index]
            let end = polyline[index + 1]

            let projection = project(location, onto: (start, end))
            if let locationAltitude = location.altitude,
               let segmentAltitude = interpolatedAltitude(start.altitude, end.altitude, projection.fraction),
               abs(locationAltitude - segmentAltitude) > maxAltitudeDifferenceMeters {
                cumulativeDistance += start.distance(to: end)
                continue
            }
            let segmentDistance = start.distance(to: end)
            let distanceAlongRoute = cumulativeDistance + segmentDistance * projection.fraction
            let candidate = PolylineSnapResult(
                coordinate: projection.coordinate,
                segmentIndex: index,
                fraction: projection.fraction,
                distanceFromPolylineMeters: projection.distance,
                distanceAlongRouteMeters: distanceAlongRoute
            )

            if best.map({ candidate.distanceFromPolylineMeters < $0.distanceFromPolylineMeters }) ?? true {
                best = candidate
            }
            cumulativeDistance += segmentDistance
        }

        return best
    }

    public func distanceAlongRoute(to coordinate: Coordinate, on polyline: [Coordinate]) -> Double? {
        snap(coordinate, to: polyline)?.distanceAlongRouteMeters
    }

    private func project(
        _ point: Coordinate,
        onto segment: (Coordinate, Coordinate)
    ) -> (coordinate: Coordinate, fraction: Double, distance: Double) {
        let referenceLatitude = point.latitude * .pi / 180.0
        let metersPerDegreeLatitude = 111_320.0
        let metersPerDegreeLongitude = metersPerDegreeLatitude * cos(referenceLatitude)

        func vector(_ coordinate: Coordinate) -> (x: Double, y: Double) {
            (
                x: (coordinate.longitude - point.longitude) * metersPerDegreeLongitude,
                y: (coordinate.latitude - point.latitude) * metersPerDegreeLatitude
            )
        }

        let start = vector(segment.0)
        let end = vector(segment.1)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        let rawFraction = lengthSquared > 0
            ? (-start.x * dx - start.y * dy) / lengthSquared
            : 0.0
        let fraction = min(1.0, max(0.0, rawFraction))
        let projectedX = start.x + dx * fraction
        let projectedY = start.y + dy * fraction
        let distance = hypot(projectedX, projectedY)
        let projected = Coordinate(
            latitude: point.latitude + projectedY / metersPerDegreeLatitude,
            longitude: point.longitude + projectedX / metersPerDegreeLongitude,
            altitude: interpolatedAltitude(segment.0.altitude, segment.1.altitude, fraction),
            bearing: segment.0.bearing(to: segment.1),
            speed: point.speed,
            horizontalAccuracy: point.horizontalAccuracy,
            timestamp: point.timestamp
        )
        return (projected, fraction, distance)
    }

    private func interpolatedAltitude(_ first: Double?, _ second: Double?, _ fraction: Double) -> Double? {
        guard let first, let second else { return first ?? second }
        return first + (second - first) * fraction
    }
}
