import AVFoundation
import Combine
import Accelerate

enum AudioState {
    case idle
    case listening
    case speaking
    case processing
}

final class UnifiedAudioEngine: ObservableObject {
    @Published var audioState: AudioState = .idle
    @Published var isRecording: Bool = false

    private let audioSession = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()

    // Simple energy-threshold VAD
    private let vadQueue = DispatchQueue(label: "audio.vad")
    private var energyThreshold: Float = -35.0 // dBFS approx

    init() {
        configureSession()
    }

    private func configureSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session config failed: \(error)")
        }
    }

    // MARK: - Listening (with simple VAD)
    func startListening(handler: @escaping (String?) -> Void) {
        guard audioState == .idle else { handler(nil); return }
        transition(to: .listening)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.vadQueue.async {
                let level = self.averagePower(buffer: buffer)
                if level > self.energyThreshold {
                    // In a later iteration, feed to SFSpeechRecognizer. For PoC scaffold, just echo.
                }
            }
        }

        engine.prepare()
        do {
            try engine.start()
            isRecording = true
        } catch {
            print("Audio engine start failed: \(error)")
            stopListening()
            handler(nil)
            return
        }

        // For scaffold, stop after 1.5 seconds and return nil (no speech)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.stopListening()
            handler(nil)
        }
    }

    func stopListening() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        if audioState == .listening { transition(to: .idle) }
    }

    // MARK: - Speaking
    func speak(_ text: String, completion: @escaping () -> Void) {
        guard audioState == .idle else { completion(); return }
        transition(to: .speaking)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48 // slightly slower than default
        utterance.volume = 0.9

        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)

        // Poll completion
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            if !synth.isSpeaking {
                timer.invalidate()
                self?.transition(to: .idle)
                completion()
            }
        }
    }

    func stopSpeaking() {
        // Minimal placeholder; AVSpeechSynthesizer instance is local per speak() for now
        transition(to: .idle)
    }

    // MARK: - Helpers
    private func averagePower(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return -120.0 }
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        vDSP_dotpr(channelData, 1, channelData, 1, &sum, vDSP_Length(frameLength))
        let meanSquare = sum / Float(frameLength)
        let power = 10 * log10f(meanSquare + 1e-7)
        return power
    }

    private func transition(to new: AudioState) {
        DispatchQueue.main.async { [weak self] in self?.audioState = new }
    }
}
