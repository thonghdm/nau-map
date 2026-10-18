import Foundation

/// Dữ liệu toàn vẹn của một tuyến đường được tính toán thành công
public struct RouteData: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    /// Danh sách các điểm polyline chi tiết của tuyến đường
    public let coordinates: [Coordinate]
    /// Danh sách các bước rẽ và chỉ dẫn Turn-by-Turn
    public let steps: [ManeuverStep]
    /// Tổng cự ly của toàn tuyến (mét)
    public let totalDistanceMeters: Double
    /// Thời gian di chuyển dự kiến (giây)
    public let estimatedDurationSeconds: TimeInterval
    /// Khung chữ nhật bao quanh toàn tuyến
    public let boundingBox: BoundingBox

    public init(
        id: String = UUID().uuidString,
        coordinates: [Coordinate],
        steps: [ManeuverStep],
        totalDistanceMeters: Double,
        estimatedDurationSeconds: TimeInterval,
        boundingBox: BoundingBox
    ) {
        self.id = id
        self.coordinates = coordinates
        self.steps = steps
        self.totalDistanceMeters = totalDistanceMeters
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.boundingBox = boundingBox
    }
}

/// Giao thức trừu tượng hóa máy chủ định tuyến (Routing Provider).
/// Có thể chuyển đổi linh hoạt giữa Vietmap API, Valhalla tự host, OSRM hoặc Mock dữ liệu offline.
public protocol RoutingProviderProtocol: Sendable {
    /// Tính toán lộ trình từ điểm xuất phát đến điểm đích
    func calculateRoute(
        from origin: Coordinate,
        to destination: Coordinate,
        waypoints: [Coordinate]
    ) async throws -> RouteData

    /// Tính toán lại lộ trình khi phát hiện tài xế đi lệch đường (Off-route)
    func recalculateRoute(
        from currentLocation: Coordinate,
        to destination: Coordinate
    ) async throws -> RouteData
}
