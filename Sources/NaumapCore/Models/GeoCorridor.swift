import Foundation

/// Khung chữ nhật bao quanh (Bounding Box) tối ưu cho câu truy vấn R*Tree index của SQLite.
public struct BoundingBox: Hashable, Codable, Sendable {
    public let minLatitude: Double
    public let maxLatitude: Double
    public let minLongitude: Double
    public let maxLongitude: Double

    public init(minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    /// Kiểm tra xem một tọa độ có nằm trong Bounding Box hay không.
    public func contains(_ coordinate: Coordinate) -> Bool {
        return coordinate.latitude >= minLatitude &&
               coordinate.latitude <= maxLatitude &&
               coordinate.longitude >= minLongitude &&
               coordinate.longitude <= maxLongitude
    }
}

/// Hành lang dự phóng di chuyển của phương tiện (Geo Corridor).
/// Dùng để giới hạn phạm vi truy vấn camera/biển báo giao thông phía trước xe.
public struct GeoCorridor: Hashable, Codable, Sendable {
    public let origin: Coordinate
    public let headingDegrees: Double
    public let lookaheadDistanceMeters: Double
    public let corridorWidthMeters: Double
    public let boundingBox: BoundingBox

    public init(
        origin: Coordinate,
        headingDegrees: Double,
        lookaheadDistanceMeters: Double,
        corridorWidthMeters: Double = 60.0 // Mặc định mở rộng 30m mỗi bên tim đường
    ) {
        self.origin = origin
        self.headingDegrees = headingDegrees
        self.lookaheadDistanceMeters = lookaheadDistanceMeters
        self.corridorWidthMeters = corridorWidthMeters

        // Tính toán 4 đỉnh của hành lang để tạo Bounding Box bao phủ
        let halfWidth = corridorWidthMeters / 2.0
        let leftBearing = (headingDegrees - 90.0 + 360.0).truncatingRemainder(dividingBy: 360.0)
        let rightBearing = (headingDegrees + 90.0).truncatingRemainder(dividingBy: 360.0)

        let p1 = origin.destination(distanceMeters: halfWidth, bearingDegrees: leftBearing)
        let p2 = origin.destination(distanceMeters: halfWidth, bearingDegrees: rightBearing)
        let frontCenter = origin.destination(distanceMeters: lookaheadDistanceMeters, bearingDegrees: headingDegrees)
        let p3 = frontCenter.destination(distanceMeters: halfWidth, bearingDegrees: leftBearing)
        let p4 = frontCenter.destination(distanceMeters: halfWidth, bearingDegrees: rightBearing)

        let latitudes = [origin.latitude, p1.latitude, p2.latitude, p3.latitude, p4.latitude]
        let longitudes = [origin.longitude, p1.longitude, p2.longitude, p3.longitude, p4.longitude]

        self.boundingBox = BoundingBox(
            minLatitude: latitudes.min() ?? origin.latitude,
            maxLatitude: latitudes.max() ?? origin.latitude,
            minLongitude: longitudes.min() ?? origin.longitude,
            maxLongitude: longitudes.max() ?? origin.longitude
        )
    }
}
