import Foundation

public struct AlertDeduplicationKey: Hashable, Sendable {
    public let pointID: String
    public let bearingBucket: Int
    public let epochID: Int64

    public init(pointID: String, bearingBucket: Int, epochID: Int64) {
        self.pointID = pointID
        self.bearingBucket = bearingBucket
        self.epochID = epochID
    }
}

/// Chống phát lặp cùng một cảnh báo trong một hướng và một phiên dữ liệu.
public struct AlertDeduplicator: Sendable {
    public let bearingBucketSize: Double
    private var emittedKeys: Set<AlertDeduplicationKey> = []

    public init(bearingBucketSize: Double = 30.0) {
        self.bearingBucketSize = bearingBucketSize
    }

    public mutating func shouldEmit(point: TrafficPoint, vehicleBearing: Double) -> Bool {
        let normalizedBearing = vehicleBearing.truncatingRemainder(dividingBy: 360.0)
        let bucket = Int(floor((normalizedBearing < 0 ? normalizedBearing + 360.0 : normalizedBearing) / bearingBucketSize))
        let key = AlertDeduplicationKey(
            pointID: point.id,
            bearingBucket: bucket,
            epochID: point.epochId
        )
        return emittedKeys.insert(key).inserted
    }

    public mutating func reset() {
        emittedKeys.removeAll(keepingCapacity: true)
    }
}
