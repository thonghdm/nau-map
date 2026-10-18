import Foundation

/// Mức độ nghiêm trọng của sự kiện cảnh báo
public enum AlertSeverity: String, Codable, Sendable {
    case info = "info"           // Thông tin nhẹ (như sắp vào trạm thu phí)
    case caution = "caution"     // Chú ý (như biển báo tốc độ trước 500m)
    case warning = "warning"     // Cảnh báo (như camera phạt nguội trước 300m)
    case critical = "critical"   // Khẩn cấp (như đang vượt quá tốc độ giới hạn cho phép)
}

/// Sự kiện cảnh báo thời gian thực được phát từ Core lên UI & Audio Layer
public struct AlertEvent: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let trafficPoint: TrafficPoint
    public let distanceMeters: Double
    public let estimatedTimeToArrivalSeconds: Double
    public let currentSpeedKmh: Double
    public let severity: AlertSeverity
    /// Đánh dấu cảnh báo có khả năng thuộc đường song song (ở chế độ FreeDrive)
    public let isAmbiguousRoute: Bool
    /// Câu thoại tiếng Việt dùng cho hệ thống TTS
    public let spokenMessage: String
    /// Tiêu đề ngắn gọn hiển thị trên CarPlay HUD / Banner
    public let visualBannerText: String
    /// Cờ yêu cầu phát âm thanh Chime (Ding!) trước khi đọc thoại
    public let requiresAudioChime: Bool
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        trafficPoint: TrafficPoint,
        distanceMeters: Double,
        estimatedTimeToArrivalSeconds: Double,
        currentSpeedKmh: Double,
        severity: AlertSeverity,
        isAmbiguousRoute: Bool = false,
        spokenMessage: String,
        visualBannerText: String,
        requiresAudioChime: Bool = true,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.trafficPoint = trafficPoint
        self.distanceMeters = distanceMeters
        self.estimatedTimeToArrivalSeconds = estimatedTimeToArrivalSeconds
        self.currentSpeedKmh = currentSpeedKmh
        self.severity = severity
        self.isAmbiguousRoute = isAmbiguousRoute
        self.spokenMessage = spokenMessage
        self.visualBannerText = visualBannerText
        self.requiresAudioChime = requiresAudioChime
        self.timestamp = timestamp
    }
}
