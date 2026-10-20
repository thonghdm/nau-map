import Foundation

public enum VoicePromptPriority: Int, Comparable, Sendable {
    case info = 0
    case caution = 1
    case warning = 2
    case critical = 3

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct VoicePrompt: Hashable, Sendable {
    public let id: String
    public let text: String
    public let priority: VoicePromptPriority
    public let requiresChime: Bool
    public let sequence: UInt64

    public init(
        id: String = UUID().uuidString,
        text: String,
        priority: VoicePromptPriority,
        requiresChime: Bool = true,
        sequence: UInt64 = 0
    ) {
        self.id = id
        self.text = text
        self.priority = priority
        self.requiresChime = requiresChime
        self.sequence = sequence
    }
}

public extension VoicePrompt {
    init(alert: AlertEvent, sequence: UInt64 = 0) {
        let priority: VoicePromptPriority
        switch alert.severity {
        case .info:
            priority = .info
        case .caution:
            priority = .caution
        case .warning:
            priority = .warning
        case .critical:
            priority = .critical
        }
        self.init(
            id: alert.id,
            text: alert.spokenMessage,
            priority: priority,
            requiresChime: alert.requiresAudioChime,
            sequence: sequence
        )
    }
}

public struct VoicePromptQueue: Sendable {
    private var prompts: [VoicePrompt] = []
    private var nextSequence: UInt64 = 0

    public init() {}

    public var isEmpty: Bool { prompts.isEmpty }
    public var count: Int { prompts.count }

    public mutating func enqueue(
        text: String,
        priority: VoicePromptPriority,
        requiresChime: Bool = true
    ) -> VoicePrompt {
        let prompt = VoicePrompt(
            text: text,
            priority: priority,
            requiresChime: requiresChime,
            sequence: nextSequence
        )
        nextSequence += 1
        prompts.append(prompt)
        return prompt
    }

    public mutating func dequeue() -> VoicePrompt? {
        guard let index = prompts.indices.max(by: {
            if prompts[$0].priority == prompts[$1].priority {
                return prompts[$0].sequence > prompts[$1].sequence
            }
            return prompts[$0].priority < prompts[$1].priority
        }) else {
            return nil
        }
        return prompts.remove(at: index)
    }

    public mutating func removeAll() {
        prompts.removeAll(keepingCapacity: true)
    }
}
