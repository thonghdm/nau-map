import Foundation

/// Phân loại đối tượng cảnh báo giao thông
public enum TrafficPointType: String, Codable, Sendable, CaseIterable {
    case speedCamera = "speed_camera"             // Camera phạt nguội tốc độ
    case redLightCamera = "red_light_camera"       // Camera phạt nguội vượt đèn đỏ
    case speedLimitSign = "speed_limit_sign"       // Biển báo giới hạn tốc độ
    case tunnelEntrance = "tunnel_entrance"       // Cửa hầm (chuyển sang Dead-Reckoning)
    case tollBooth = "toll_booth"                 // Trạm thu phí / ETC
    case sharpCurve = "sharp_curve"               // Khúc cua nguy hiểm
    case accidentBlackspot = "accident_blackspot" // Điểm đen tai nạn
}

/// Điểm cảnh báo giao thông trong hệ thống spatial index
public struct TrafficPoint: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let type: TrafficPointType
    public let coordinate: Coordinate
    /// Góc phương vị giám sát của camera/biển báo (0° - 360°).
    /// Nếu nil nghĩa là cảnh báo mọi hướng (omni-directional).
    public let targetBearing: Double?
    /// Dung sai góc mở (mặc định ±30° theo tài liệu kỹ thuật).
    public let bearingTolerance: Double
    /// Tốc độ giới hạn (km/h) nếu có
    public let speedLimitKmH: Int?
    /// Cờ đánh dấu điểm này nằm trên cầu vượt (True) hay gầm cầu (False)
    public let isOverpassOrUpperLevel: Bool
    /// Cờ đánh dấu thuộc đường gom/đường song song
    public let isParallelRoad: Bool
    public let title: String
    public let subtitle: String?
    /// Định danh phiên bản cập nhật dữ liệu để đồng bộ delta và chống spam
    public let epochId: Int64

    public init(
        id: String,
        type: TrafficPointType,
        coordinate: Coordinate,
        targetBearing: Double? = nil,
        bearingTolerance: Double = 30.0,
        speedLimitKmH: Int? = nil,
        isOverpassOrUpperLevel: Bool = false,
        isParallelRoad: Bool = false,
        title: String,
        subtitle: String? = nil,
        epochId: Int64 = 0
    ) {
        self.id = id
        self.type = type
        self.coordinate = coordinate
        self.targetBearing = targetBearing
        self.bearingTolerance = bearingTolerance
        self.speedLimitKmH = speedLimitKmH
        self.isOverpassOrUpperLevel = isOverpassOrUpperLevel
        self.isParallelRoad = isParallelRoad
        self.title = title
        self.subtitle = subtitle
        self.epochId = epochId
    }

    /// Kiểm tra hướng di chuyển của phương tiện có nằm trong góc quét của điểm cảnh báo hay không.
    public func matchesBearing(_ currentBearing: Double) -> Bool {
        guard let target = targetBearing else {
            // Không giới hạn góc (cảnh báo mọi hướng)
            return true
        }

        let diff = abs(target - currentBearing).truncatingRemainder(dividingBy: 360.0)
        let angularDistance = diff > 180.0 ? 360.0 - diff : diff
        return angularDistance <= bearingTolerance
    }
}
