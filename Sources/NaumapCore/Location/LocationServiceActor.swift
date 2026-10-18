import Foundation

/// Bộ xử lý vị trí tập trung (Location Service Actor).
/// Chịu trách nhiệm:
/// 1. Lọc nhiễu GPS (loại bỏ tọa độ có sai số horizontalAccuracy > 20m).
/// 2. Giám sát tình trạng mất tín hiệu (Timeout > 2.0 giây).
/// 3. Tự động kích hoạt Dead-Reckoning Engine khi xe vào hầm hoặc mất GPS.
/// 4. Phát ra luồng vị trí chuẩn hóa `AsyncStream<Coordinate>`.
public actor LocationServiceActor: LocationProviderProtocol {
    /// Giới hạn sai số GPS tối đa được chấp nhận (mặc định 20m theo Architecture Plan)
    public let maxAccuracyThreshold: Double
    /// Thời gian tối đa không có tín hiệu GPS trước khi kích hoạt Dead-Reckoning (giây)
    public let gpsLossTimeoutSeconds: TimeInterval

    private let deadReckoningEngine: DeadReckoningEngine
    private var isRunning: Bool = false
    private var lastValidLocation: Coordinate?
    private var lastLocationTime: Date?
    private var activeTunnelPolyline: [Coordinate]?

    // AsyncStream continuation quản lý các subscriber
    private var streamContinuation: AsyncStream<Coordinate>.Continuation?
    public nonisolated let locationStream: AsyncStream<Coordinate>

    public var currentLocation: Coordinate? {
        return lastValidLocation
    }

    public init(
        maxAccuracyThreshold: Double = 20.0,
        gpsLossTimeoutSeconds: TimeInterval = 2.0,
        deadReckoningEngine: DeadReckoningEngine = DeadReckoningEngine()
    ) {
        self.maxAccuracyThreshold = maxAccuracyThreshold
        self.gpsLossTimeoutSeconds = gpsLossTimeoutSeconds
        self.deadReckoningEngine = deadReckoningEngine

        var continuation: AsyncStream<Coordinate>.Continuation?
        self.locationStream = AsyncStream<Coordinate> { cont in
            continuation = cont
        }
        self.streamContinuation = continuation
    }

    /// Thiết lập lộ trình trong hầm nếu có (để Dead-Reckoning bám theo đường hầm)
    public func setTunnelPolyline(_ polyline: [Coordinate]?) {
        self.activeTunnelPolyline = polyline
    }

    public func startUpdating() async throws {
        isRunning = true
    }

    public func stopUpdating() async {
        isRunning = false
    }

    /// Tiếp nhận tọa độ thô từ CoreLocation hoặc bộ giả lập
    /// Trả về `true` nếu tọa độ hợp lệ và được gửi đi; `false` nếu bị lọc do sai số lớn.
    @discardableResult
    public func processRawLocation(_ location: Coordinate) -> Bool {
        guard isRunning else { return false }

        // 1. Quality Check: Lọc sai số GPS theo tiêu chuẩn P0
        if let accuracy = location.horizontalAccuracy {
            if accuracy < 0 || accuracy > maxAccuracyThreshold {
                // Sai số quá lớn (> 20m) hoặc tín hiệu âm -> Bỏ qua
                return false
            }
        }

        // Tọa độ hợp lệ
        self.lastValidLocation = location
        self.lastLocationTime = location.timestamp

        // Phát ra stream cho các consumer
        streamContinuation?.yield(location)
        return true
    }

    /// Thực hiện bước ước lượng Dead-Reckoning nếu GPS bị mất
    /// - Parameter currentTime: Mốc thời gian hiện tại để tính độ lệch thời gian
    /// - Returns: Tọa độ ước lượng kèm mức tin cậy (nếu đang ở trạng thái mất GPS)
    public func performDeadReckoningTick(currentTime: Date = Date()) -> (Coordinate, DeadReckoningConfidence)? {
        guard isRunning, let lastLoc = lastValidLocation, let lastTime = lastLocationTime else {
            return nil
        }

        let elapsed = currentTime.timeIntervalSince(lastTime)
        guard elapsed >= gpsLossTimeoutSeconds else {
            // Vẫn còn trong ngưỡng GPS bình thường, không cần Dead-Reckoning
            return nil
        }

        let lastSpeed = lastLoc.speed ?? 0.0
        let lastBearing = lastLoc.bearing ?? 0.0

        let (estimatedCoord, confidence) = deadReckoningEngine.estimateLocation(
            lastLocation: lastLoc,
            lastSpeedMps: lastSpeed,
            lastBearing: lastBearing,
            elapsedSeconds: elapsed,
            tunnelPolyline: activeTunnelPolyline
        )

        // Cung cấp tọa độ ước lượng vào luồng cho UI/Engine cập nhật
        streamContinuation?.yield(estimatedCoord)
        return (estimatedCoord, confidence)
    }

    deinit {
        streamContinuation?.finish()
    }
}
