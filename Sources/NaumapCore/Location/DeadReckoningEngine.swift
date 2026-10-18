import Foundation

/// Động cơ Dead-Reckoning (Ước lượng vị trí khi mất tín hiệu GPS).
/// Áp dụng thuật toán suy giảm vận tốc (Confidence Decay) khi xe chạy vào hầm hoặc mất sóng GPS.
public struct DeadReckoningEngine: Sendable {
    /// Hệ số suy giảm vận tốc mỗi giây khi không có gia tốc đo được (mặc định 0.98)
    public let decayFactor: Double
    /// Ngưỡng thời gian giữ mức tin cậy cao (mặc định 15 giây)
    public let highConfidenceTimeout: TimeInterval
    /// Ngưỡng thời gian tối đa trước khi coi như mất hoàn toàn tín hiệu (mặc định 45 giây)
    public let signalLostTimeout: TimeInterval

    public init(
        decayFactor: Double = 0.98,
        highConfidenceTimeout: TimeInterval = 15.0,
        signalLostTimeout: TimeInterval = 45.0
    ) {
        self.decayFactor = decayFactor
        self.highConfidenceTimeout = highConfidenceTimeout
        self.signalLostTimeout = signalLostTimeout
    }

    /// Đánh giá mức độ tin cậy dựa trên thời gian mất sóng GPS (giây)
    public func evaluateConfidence(elapsedSeconds: TimeInterval) -> DeadReckoningConfidence {
        if elapsedSeconds < highConfidenceTimeout {
            return .high
        } else if elapsedSeconds < signalLostTimeout {
            return .low
        } else {
            return .signalLost
        }
    }

    /// Tính toán quãng đường ước lượng xe đã đi được sau `elapsedSeconds` (tính theo mét)
    /// Sử dụng công thức suy giảm: S = V_last * dt * (alpha ^ dt)
    public func estimateDistanceTraveled(
        lastKnownSpeedMps: Double,
        elapsedSeconds: TimeInterval
    ) -> Double {
        guard elapsedSeconds > 0, lastKnownSpeedMps > 0 else { return 0.0 }
        let effectiveDecay = pow(decayFactor, elapsedSeconds)
        return lastKnownSpeedMps * elapsedSeconds * effectiveDecay
    }

    /// Ước lượng vị trí mới dựa trên vị trí cuối cùng trước khi mất GPS
    /// - Parameters:
    ///   - lastLocation: Tọa độ hợp lệ cuối cùng nhận được từ GPS
    ///   - lastSpeedMps: Vận tốc cuối cùng (m/s)
    ///   - lastBearing: Hướng di chuyển cuối cùng (độ)
    ///   - elapsedSeconds: Thời gian đã trôi qua kể từ tọa độ cuối (giây)
    ///   - tunnelPolyline: Polyline lộ trình trong hầm (nếu đang ở chế độ Navigating)
    /// - Returns: Tuple gồm tọa độ ước lượng và mức độ tin cậy
    public func estimateLocation(
        lastLocation: Coordinate,
        lastSpeedMps: Double,
        lastBearing: Double,
        elapsedSeconds: TimeInterval,
        tunnelPolyline: [Coordinate]? = nil
    ) -> (coordinate: Coordinate, confidence: DeadReckoningConfidence) {
        let confidence = evaluateConfidence(elapsedSeconds: elapsedSeconds)

        // Nếu vượt quá 45 giây, ngừng dự phóng để tránh đưa xe đi quá xa thực tế
        if confidence == .signalLost {
            return (lastLocation, .signalLost)
        }

        let distanceMeters = estimateDistanceTraveled(
            lastKnownSpeedMps: lastSpeedMps,
            elapsedSeconds: elapsedSeconds
        )

        // Nếu có Polyline hầm, dự phóng dọc theo Polyline để không bị lệch tim đường
        if let polyline = tunnelPolyline, !polyline.isEmpty {
            let projectedCoord = projectAlongPolyline(
                from: lastLocation,
                distanceMeters: distanceMeters,
                polyline: polyline
            )
            return (projectedCoord, confidence)
        }

        // Nếu không có Polyline (FreeDrive), dự phóng theo góc phương vị cuối cùng
        let projected = lastLocation.destination(
            distanceMeters: distanceMeters,
            bearingDegrees: lastBearing
        )

        let decayedSpeed = lastSpeedMps * pow(decayFactor, elapsedSeconds)
        let estimatedCoord = Coordinate(
            latitude: projected.latitude,
            longitude: projected.longitude,
            altitude: lastLocation.altitude,
            bearing: lastBearing,
            speed: decayedSpeed,
            horizontalAccuracy: 15.0 + (elapsedSeconds * 0.5), // Sai số tăng dần theo thời gian
            timestamp: Date()
        )

        return (estimatedCoord, confidence)
    }

    /// Phép chiếu khoảng cách di chuyển dọc theo danh sách các điểm Polyline
    private func projectAlongPolyline(
        from origin: Coordinate,
        distanceMeters: Double,
        polyline: [Coordinate]
    ) -> Coordinate {
        guard polyline.count > 1 else { return origin }

        var remainingDist = distanceMeters
        var currentPoint = origin

        // Tìm điểm xuất phát gần nhất trên polyline
        var startIndex = 0
        var minDistance = Double.infinity
        for (i, pt) in polyline.enumerated() {
            let d = origin.distance(to: pt)
            if d < minDistance {
                minDistance = d
                startIndex = i
            }
        }

        for i in startIndex..<(polyline.count - 1) {
            let pA = (i == startIndex) ? currentPoint : polyline[i]
            let pB = polyline[i + 1]
            let segmentDist = pA.distance(to: pB)

            if segmentDist <= 0.001 { continue }

            if remainingDist <= segmentDist {
                let fraction = remainingDist / segmentDist
                let bearing = pA.bearing(to: pB)
                return pA.destination(distanceMeters: remainingDist, bearingDegrees: bearing)
            } else {
                remainingDist -= segmentDist
                currentPoint = pB
            }
        }

        return polyline.last ?? origin
    }
}
