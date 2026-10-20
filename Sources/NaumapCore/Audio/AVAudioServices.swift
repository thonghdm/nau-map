#if canImport(AVFoundation)
import AVFoundation

/// Apple platform adapter for CarPlay/iPhone audio prompts.
public final class AVAudioDuckingService: AudioDuckingController, @unchecked Sendable {
    private let session: AVAudioSession

    public init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
    }

    public func beginDucking() async throws {
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try session.setActive(true, options: [])
    }

    public func endDucking() async throws {
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

public final class AVVoicePromptService: NSObject, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private let locale: Locale

    public init(locale: Locale = Locale(identifier: "vi-VN")) {
        self.locale = locale
    }

    public func speak(_ prompt: VoicePrompt) {
        let utterance = AVSpeechUtterance(string: prompt.text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
#endif
