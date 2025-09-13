import Foundation

final class IntentClassifier {
    enum UserIntent: String {
        case startWorkout = "start_workout"
        case stopWorkout = "stop_workout"
        case pauseWorkout = "pause_workout"
        case nextExercise = "next_exercise"
        case questionForm = "question_form"
        case questionProgress = "question_progress"
        case directCommand = "direct_command"
        case questionForCoach = "question_for_coach"
        case ambient = "ambient_chatter"
        case silence = "silence"
        case unknown = "unknown"
    }

    func classify(_ text: String?) -> UserIntent {
        let t = (text ?? "").lowercased()
        if t.isEmpty { return .silence }

        if t.contains("stop") || t.contains("end") { return .directCommand }
        if t.contains("pause") { return .directCommand }
        if t.contains("next") || t.contains("skip") { return .directCommand }

        if t.contains("how many") || t.contains("reps left") { return .questionForCoach }
        if (t.contains("form") && t.contains("how")) || t.contains("how was that") { return .questionForCoach }

        return .unknown
    }
}
