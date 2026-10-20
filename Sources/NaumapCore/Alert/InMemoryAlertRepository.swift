import Foundation

/// Repository thuần Swift dùng cho test, GPX playback và fallback khi chưa có SQLite.
public actor InMemoryAlertRepository: AlertRepositoryProtocol {
    private var points: [String: TrafficPoint] = [:]

    public init(points: [TrafficPoint] = []) {
        for point in points {
            self.points[point.id] = point
        }
    }

    public func fetchCandidates(in boundingBox: BoundingBox) async throws -> [TrafficPoint] {
        points.values.filter { boundingBox.contains($0.coordinate) }
    }

    public func fetchCandidates(in corridor: GeoCorridor) async throws -> [TrafficPoint] {
        points.values.filter { corridor.contains($0.coordinate) }
    }

    public func upsert(points: [TrafficPoint]) async throws {
        for point in points {
            self.points[point.id] = point
        }
    }

    public func delete(pointIds: [String]) async throws {
        for id in pointIds {
            points.removeValue(forKey: id)
        }
    }

    public func countTotalPoints() async throws -> Int {
        points.count
    }

    public func syncDelta(since epochId: Int64) async throws -> Int {
        points.values.filter { $0.epochId > epochId }.count
    }
}
