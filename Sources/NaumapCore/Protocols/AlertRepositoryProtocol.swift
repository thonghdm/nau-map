import Foundation

/// Giao thức trừu tượng hóa kho dữ liệu không gian cảnh báo giao thông (Spatial Alert Repository).
/// Phục vụ việc lưu trữ cục bộ (GRDB SQLite R*Tree) và đồng bộ gia tăng (Delta Sync) từ máy chủ.
public protocol AlertRepositoryProtocol: Sendable {
    /// Truy vấn nhanh các điểm cảnh báo nằm trong Bounding Box (sử dụng SQLite R*Tree index)
    func fetchCandidates(in boundingBox: BoundingBox) async throws -> [TrafficPoint]

    /// Truy vấn và lọc các điểm cảnh báo nằm trong hành lang di chuyển phía trước xe
    func fetchCandidates(in corridor: GeoCorridor) async throws -> [TrafficPoint]

    /// Chèn hoặc cập nhật một danh sách các điểm cảnh báo vào cơ sở dữ liệu
    func upsert(points: [TrafficPoint]) async throws

    /// Xóa các điểm cảnh báo theo danh sách ID
    func delete(pointIds: [String]) async throws

    /// Lấy tổng số lượng điểm cảnh báo đang được lưu trong cache cục bộ
    func countTotalPoints() async throws -> Int

    /// Đồng bộ gói dữ liệu cập nhật mới nhất tính từ epochId đã lưu
    func syncDelta(since epochId: Int64) async throws -> Int
}
