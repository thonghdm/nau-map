import Foundation

public enum AudioDuckingState: Equatable, Sendable {
    case idle
    case ducking
    case restoring
}

public protocol AudioDuckingController: Sendable {
    func beginDucking() async throws
    func endDucking() async throws
}

public struct AudioPromptCoordinator: Sendable {
    public let duckedVolume: Double
    public private(set) var state: AudioDuckingState = .idle

    public init(duckedVolume: Double = 0.3) {
        self.duckedVolume = min(1.0, max(0.0, duckedVolume))
    }

    public mutating func startedPrompt() -> AudioDuckingState {
        state = .ducking
        return state
    }

    public mutating func finishedPrompt() -> AudioDuckingState {
        state = .restoring
        return state
    }

    public mutating func restored() -> AudioDuckingState {
        state = .idle
        return state
    }
}
