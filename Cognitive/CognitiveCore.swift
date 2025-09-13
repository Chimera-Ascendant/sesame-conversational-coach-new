import Foundation
import Combine

final class CognitiveCore: ObservableObject {
    @Published var isWorkoutActive: Bool = false
    @Published var lastCoachingCue: String = ""

    private let perception: PerceptionEngine
    private let audio: UnifiedAudioEngine
    private let intents = IntentClassifier()
    private var client: CognitiveClient
    private let motion = MotionManager.shared

    private var timer: Timer?
    private var lastCueTime: Date = .distantPast
    private var cancellables = Set<AnyCancellable>()

    // Cue budget
    private let minCueInterval: TimeInterval = 8.0

    init(perception: PerceptionEngine, audio: UnifiedAudioEngine, client: CognitiveClient = CognitiveClient()) {
        self.perception = perception
        self.audio = audio
        self.client = client
    }

    func startWorkout() {
        guard !isWorkoutActive else { return }
        isWorkoutActive = true
        lastCueTime = .distantPast
        timer?.invalidate()
        motion.start()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        speak("Starting workout. I'll keep it concise.")
    }

    func pauseWorkout() {
        guard isWorkoutActive else { return }
        timer?.invalidate()
        isWorkoutActive = false
        motion.stop()
        speak("Workout paused.")
    }

    func endWorkout() {
        timer?.invalidate()
        isWorkoutActive = false
        motion.stop()
        speak("Workout complete. Great work today.")
    }

    func processVoiceCommand(_ text: String) {
        let intent = intents.classify(text)
        switch intent {
        case .directCommand:
            if text.lowercased().contains("stop") || text.lowercased().contains("end") { endWorkout() }
            else if text.lowercased().contains("pause") { pauseWorkout() }
            else if text.lowercased().contains("next") || text.lowercased().contains("skip") { speak("Okay, moving to the next exercise.") }
        case .questionForCoach:
            queryCognitiveCore(userText: text)
        default:
            break
        }
    }

    private func tick() {
        guard isWorkoutActive else { return }
        // Gather latest IMU + baro ring buffer and run perception
        let snap = motion.snapshot()
        perception.infer(snapshot: snap)
        // Proactive check – query with silence intent to get short coach cue if needed
        queryCognitiveCore(userText: "")
    }

    private func queryCognitiveCore(userText: String) {
        let now = Date()
        // Respect cue budget unless there is a user question
        let isQuestion = !userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !isQuestion && now.timeIntervalSince(lastCueTime) < minCueInterval { return }

        let req = CognitiveRequest(
            transaction_id: UUID().uuidString,
            timestamp_ms: Int(Date().timeIntervalSince1970 * 1000),
            user_state: .init(physical_fatigue: Double(perception.fatigueLevel), mental_focus: 0.7, consecutive_form_errors: 0),
            motion_data: .init(
                exercise_id: perception.currentExercise.rawValue,
                rep_count_total: perception.repCount,
                current_set_target_reps: 20,
                form_error_detected: perception.formQuality == .needsWork ? "generic" : "none",
                metrics: .init(jitter_percent_increase: 0.0, velocity_percent_decrease: 0.0),
                uncertainty_score: 0.9
            ),
            user_utterance: .init(transcribed_text: userText, intent: isQuestion ? "question_for_coach" : "silence"),
            session_state: .init(time_since_last_cue_ms: Int(now.timeIntervalSince(lastCueTime) * 1000))
        )

        client.infer(req) { [weak self] resp in
            guard let self = self, let resp = resp else { return }
            let text = resp.response.text_to_speak
            DispatchQueue.main.async {
                self.deliverCue(text)
            }
        }
    }

    private func deliverCue(_ text: String) {
        guard !text.isEmpty else { return }
        let now = Date()
        if now.timeIntervalSince(lastCueTime) < minCueInterval { return }
        lastCueTime = now
        lastCoachingCue = text
        speak(text)
    }

    private func speak(_ text: String) {
        audio.speak(text) {}
    }

    // Update networking client (e.g., after settings change)
    func updateClient(_ newClient: CognitiveClient) {
        self.client = newClient
    }
}
