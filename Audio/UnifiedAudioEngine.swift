import AVFoundation
import Combine
import Accelerate
import Speech

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
    private let synth = AVSpeechSynthesizer()

    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

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

    // MARK: - ASR: single-utterance transcription
    func transcribeOnce(timeout: TimeInterval = 6.0, handler: @escaping (String?) -> Void) {
        guard audioState == .idle else { handler(nil); return }
        requestSpeechPermissions { [weak self] granted in
            guard let self = self, granted else { handler(nil); return }
            self.startASR(handler: handler, timeout: timeout)
        }
    }

    private func startASR(handler: @escaping (String?) -> Void, timeout: TimeInterval) {
        transition(to: .listening)
        recognitionTask?.cancel(); recognitionTask = nil
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
            isRecording = true
        } catch {
            print("Audio engine start failed: \(error)")
            stopASR()
            handler(nil)
            return
        }

        var bestFinal: String?
        var lastAudioAt = Date()

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { [weak self] result, error in
            if let res = result {
                let text = res.bestTranscription.formattedString
                if !text.isEmpty { lastAudioAt = Date() }
                if res.isFinal { bestFinal = text; self?.stopASR(); handler(text); }
            }
            if error != nil { self?.stopASR(); handler(bestFinal) }
        })

        // Silence timeout watchdog
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self = self else { return }
            if Date().timeIntervalSince(lastAudioAt) >= timeout {
                let text = bestFinal
                self.stopASR(); handler(text)
            }
        }
    }

    func stopASR() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        if audioState == .listening { transition(to: .idle) }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
    }

    // MARK: - Speaking
    func speak(_ text: String, completion: @escaping () -> Void) {
        guard audioState == .idle else { completion(); return }
        transition(to: .speaking)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48 // slightly slower than default
        utterance.volume = 0.9
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

    func stopSpeaking() { synth.stopSpeaking(at: .immediate); transition(to: .idle) }

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

    private func requestSpeechPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}
