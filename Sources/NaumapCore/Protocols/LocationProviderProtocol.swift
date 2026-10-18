import Foundation

/// Giao thức cung cấp luồng tọa độ vị trí (Location Provider).
/// Trừu tượng hóa hoàn toàn giữa CoreLocation thật trên iOS và GPX Playback Mock phục vụ Unit Test / Simulator.
public protocol LocationProviderProtocol: Sendable {
    /// Luồng bất đồng bộ cung cấp tọa độ xe thời gian thực
    var locationStream: AsyncStream<Coordinate> { get }

    /// Vị trí mới nhất hiện tại (nếu có)
    var currentLocation: Coordinate? { get async }

    /// Bắt đầu lắng nghe và truyền phát tọa độ
    func startUpdating() async throws

    /// Tạm dừng hoặc dừng cập nhật tọa độ
    func stopUpdating() async
}
