import Foundation

/// Phân loại chỉ dẫn điều hướng (Turn-by-turn Maneuver)
public enum ManeuverType: String, Codable, Sendable, CaseIterable {
    case straight = "straight"
    case slightLeft = "slight_left"
    case slightRight = "slight_right"
    case turnLeft = "turn_left"
    case turnRight = "turn_right"
    case sharpLeft = "sharp_left"
    case sharpRight = "sharp_right"
    case uTurn = "u_turn"
    case keepLeft = "keep_left"
    case keepRight = "keep_right"
    case takeFork = "take_fork"
    case roundabout = "roundabout"
    case enterTunnel = "enter_tunnel"
    case exitTunnel = "exit_tunnel"
    case arrive = "arrive"
}

/// Bước chỉ dẫn dẫn đường chi tiết
public struct ManeuverStep: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let instruction: String
    public let type: ManeuverType
    public let coordinate: Coordinate
    public let distanceToNextStepMeters: Double
    public let remainingDurationSeconds: TimeInterval
    public let roadName: String?
    public let roundaboutExitIndex: Int?

    public init(
        id: String = UUID().uuidString,
        instruction: String,
        type: ManeuverType,
        coordinate: Coordinate,
        distanceToNextStepMeters: Double,
        remainingDurationSeconds: TimeInterval,
        roadName: String? = nil,
        roundaboutExitIndex: Int? = nil
    ) {
        self.id = id
        self.instruction = instruction
        self.type = type
        self.coordinate = coordinate
        self.distanceToNextStepMeters = distanceToNextStepMeters
        self.remainingDurationSeconds = remainingDurationSeconds
        self.roadName = roadName
        self.roundaboutExitIndex = roundaboutExitIndex
    }
}
