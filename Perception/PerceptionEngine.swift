import Foundation
import Combine

final class PerceptionEngine: ObservableObject {
    enum Exercise: String, CaseIterable {
        case standingMarch = "standing_march"
        case armCircles = "arm_circles"
        case stepTouch = "step_touch"
        case wallPushup = "wall_pushup"
        case seatedExtension = "seated_extension"
        case unknown = "unknown"
    }

    enum FormQuality: String {
        case excellent, good, needsWork, unknown
    }

    @Published var currentExercise: Exercise = .unknown
    @Published var formQuality: FormQuality = .unknown
    @Published var repCount: Int = 0
    @Published var fatigueLevel: Float = 0.0

    func processMockFrame() {
        // Placeholder until Core ML model is integrated
        // Increment a fake rep count and randomize fatigue slightly
        repCount += 1
        fatigueLevel = min(1.0, fatigueLevel + 0.02)
        if repCount % 3 == 0 { formQuality = .good }
        currentExercise = .standingMarch
    }
}
