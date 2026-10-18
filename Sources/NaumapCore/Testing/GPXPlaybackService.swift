import Foundation

/// Bộ phát lại hành trình GPX / Giả lập vị trí di chuyển xe (GPX Playback Simulator).
/// Cho phép lập trình viên chạy kiểm thử dẫn đường và cảnh báo tự động trên máy tính
/// mà không cần phải lái xe ra đường thật hay kết nối thiết bị CarPlay vật lý.
public final class GPXPlaybackService: LocationProviderProtocol, @unchecked Sendable {
    public let waypoints: [Coordinate]
    public let playbackSpeedMultiplier: Double
    /// Vùng giả lập mất GPS (ví dụ khi xe vào hầm Thủ Thiêm từ chỉ số index A đến B)
    public var gpsLossIndexRange: ClosedRange<Int>?

    private var currentIndex: Int = 0
    private var isPlaying: Bool = false
    private var playbackTask: Task<Void, Never>?

    private let streamContinuation: AsyncStream<Coordinate>.Continuation
    public let locationStream: AsyncStream<Coordinate>

    private let lock = NSLock()
    private var _currentLocation: Coordinate?

    public var currentLocation: Coordinate? {
        lock.lock()
        defer { lock.unlock() }
        return _currentLocation
    }

    public init(
        waypoints: [Coordinate],
        playbackSpeedMultiplier: Double = 1.0,
        gpsLossIndexRange: ClosedRange<Int>? = nil
    ) {
        self.waypoints = waypoints
        self.playbackSpeedMultiplier = max(0.1, playbackSpeedMultiplier)
        self.gpsLossIndexRange = gpsLossIndexRange

        var continuation: AsyncStream<Coordinate>.Continuation!
        self.locationStream = AsyncStream<Coordinate> { cont in
            continuation = cont
        }
        self.streamContinuation = continuation
    }

    public func startUpdating() async throws {
        lock.lock()
        guard !isPlaying else {
            lock.unlock()
            return
        }
        isPlaying = true
        currentIndex = 0
        lock.unlock()

        startPlaybackLoop()
    }

    public func stopUpdating() async {
        lock.lock()
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
        lock.unlock()
    }

    /// Đưa vào 1 tọa độ thủ công tại một bước cụ thể (hỗ trợ Unit Test tức thì không cần đợi sleep)
    @discardableResult
    public func stepNext() -> Coordinate? {
        lock.lock()
        defer { lock.unlock() }

        guard currentIndex < waypoints.count else {
            return nil
        }

        let index = currentIndex
        currentIndex += 1

        // Kiểm tra xem vị trí này có rơi vào vùng giả lập mất sóng không
        if let lossRange = gpsLossIndexRange, lossRange.contains(index) {
            // Giả lập mất sóng: Không phát tọa độ
            return nil
        }

        let coord = waypoints[index]
        _currentLocation = coord
        streamContinuation.yield(coord)
        return coord
    }

    private func startPlaybackLoop() {
        playbackTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                let coord = self.stepNext()

                if self.lock.withLock({ self.currentIndex >= self.waypoints.count }) {
                    // Đã phát hết danh sách điểm
                    break
                }

                // Tính thời gian chờ giữa 2 điểm (mặc định 1 giây / speedMultiplier)
                let sleepSeconds = 1.0 / self.playbackSpeedMultiplier
                let sleepNanos = UInt64(sleepSeconds * 1_000_000_000)

                do {
                    try await Task.sleep(nanoseconds: sleepNanos)
                } catch {
                    break
                }
            }
        }
    }

    deinit {
        streamContinuation.finish()
        playbackTask?.cancel()
    }
}
