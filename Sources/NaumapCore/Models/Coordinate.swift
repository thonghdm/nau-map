import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Tọa độ địa lý thuần túy (Pure Swift), độc lập hoàn toàn với framework UI.
/// Hỗ trợ tính toán khoảng cách theo công thức Haversine và góc phương vị (bearing).
public struct Coordinate: Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let bearing: Double?          // Góc di chuyển tính theo độ (0° - 360°, North = 0°)
    public let speed: Double?            // Vận tốc (m/s)
    public let horizontalAccuracy: Double? // Sai số bán kính định vị (m)
    public let timestamp: Date

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        bearing: Double? = nil,
        speed: Double? = nil,
        horizontalAccuracy: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.bearing = bearing
        self.speed = speed
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }

    /// Tính khoảng cách đường chim bay (Great Circle Distance) theo công thức Haversine (đơn vị: mét).
    public func distance(to other: Coordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = self.latitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let dLat = (other.latitude - self.latitude) * .pi / 180.0
        let dLon = (other.longitude - self.longitude) * .pi / 180.0

        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))

        return earthRadiusMeters * c
    }

    /// Tính góc phương vị (Initial Bearing) từ điểm hiện tại đến điểm đích (đơn vị: 0° đến 360°).
    public func bearing(to destination: Coordinate) -> Double {
        let lat1 = self.latitude * .pi / 180.0
        let lat2 = destination.latitude * .pi / 180.0
        let dLon = (destination.longitude - self.longitude) * .pi / 180.0

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180.0 / .pi

        return (degrees + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    /// Tính tọa độ điểm đến sau khi di chuyển một khoảng cách `distanceMeters` theo góc `bearingDegrees`.
    public func destination(distanceMeters: Double, bearingDegrees: Double) -> Coordinate {
        let earthRadiusMeters = 6_371_000.0
        let angularDist = distanceMeters / earthRadiusMeters
        let bearingRad = bearingDegrees * .pi / 180.0

        let lat1 = self.latitude * .pi / 180.0
        let lon1 = self.longitude * .pi / 180.0

        let lat2 = asin(sin(lat1) * cos(angularDist) + cos(lat1) * sin(angularDist) * cos(bearingRad))
        let lon2 = lon1 + atan2(
            sin(bearingRad) * sin(angularDist) * cos(lat1),
            cos(angularDist) - sin(lat1) * sin(lat2)
        )

        return Coordinate(
            latitude: lat2 * 180.0 / .pi,
            longitude: lon2 * 180.0 / .pi,
            altitude: self.altitude,
            bearing: bearingDegrees,
            speed: self.speed,
            horizontalAccuracy: self.horizontalAccuracy,
            timestamp: self.timestamp
        )
    }
}

#if canImport(CoreLocation)
extension Coordinate {
    /// Adapter khởi tạo tiện ích từ CLLocation (khi chạy trên nền tảng Apple)
    public init(clLocation: CLLocation) {
        self.init(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude,
            altitude: clLocation.altitude,
            bearing: clLocation.course >= 0 ? clLocation.course : nil,
            speed: clLocation.speed >= 0 ? clLocation.speed : nil,
            horizontalAccuracy: clLocation.horizontalAccuracy >= 0 ? clLocation.horizontalAccuracy : nil,
            timestamp: clLocation.timestamp
        )
    }
}
#endif
