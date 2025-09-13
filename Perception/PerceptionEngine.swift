import Foundation
import Combine
import CoreML

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
    // Debug telemetry
    @Published var debugExerciseLogits: [Float] = []
    @Published var debugFormLogits: [Float] = []
    @Published var debugRepMean: Float = 0.0

    private var model: MLModel?
    private let sequenceLength = 300
    private let channels = 8

    init() {
        loadModel()
    }

    private func loadModel() {
        // Load ML Program package from bundle
        if let url = Bundle.main.url(forResource: "ChimeraPerception", withExtension: "mlpackage") {
            do {
                let cfg = MLModelConfiguration()
                cfg.computeUnits = .all
                model = try MLModel(contentsOf: url, configuration: cfg)
                print("✅ Loaded Core ML model")
            } catch {
                print("❌ Failed to load Core ML model: \(error)")
            }
        } else {
            print("⚠️ ChimeraPerception.mlpackage not found in bundle")
        }
    }

    // In a later iteration, we will append real IMU frames. For now, run with zeros to validate pipeline.
    func inferIfReady() {
        guard let model else { return }
        do {
            let shape: [NSNumber] = [1, channels as NSNumber, sequenceLength as NSNumber]
            let arr = try MLMultiArray(shape: shape, dataType: .float32)
            // zeros by default
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "sensor_data": MLFeatureValue(multiArray: arr)
            ])
            let out = try model.prediction(from: provider)

            // Parse outputs
            if let ex = out.featureValue(for: "exercise_logits")?.multiArrayValue {
                let idx = argmax1D(ex)
                currentExercise = Exercise(rawValue: labelForExercise(idx)) ?? .unknown
                debugExerciseLogits = toArray(ex)
            }
            if let fatigue = out.featureValue(for: "fatigue_score")?.multiArrayValue {
                fatigueLevel = Float(truncating: fatigue[idx1D: 0])
            }
            if let rep = out.featureValue(for: "rep_probs")?.multiArrayValue {
                // Very simple peak proxy: if mean prob > 0.5, count 1
                let mean = mean1D(rep)
                debugRepMean = mean
                if mean > 0.5 { repCount += 1 }
            }
            // Form quality placeholder from form logits: not mapped yet to discrete labels
            if let form = out.featureValue(for: "form_logits")?.multiArrayValue {
                let idx = argmax1D(form)
                formQuality = idx == 0 ? .excellent : (idx == 1 ? .needsWork : .good)
                debugFormLogits = toArray(form)
            }
        } catch {
            print("❌ Inference error: \(error)")
        }
    }

    // Accepts snapshot shaped [T, 8] and runs a forward pass.
    func infer(snapshot: [[Float]]) {
        guard let model else { return }
        guard snapshot.count == sequenceLength else {
            // If not enough frames yet, skip
            return
        }
        do {
            let shape: [NSNumber] = [1, channels as NSNumber, sequenceLength as NSNumber]
            let arr = try MLMultiArray(shape: shape, dataType: .float32)
            // Copy data: input is [B=1, C=8, T]
            for t in 0..<sequenceLength {
                let row = snapshot[t]
                // accel xyz -> channels 0..2, gyro xyz -> 3..5, baro -> 6..7
                for c in 0..<min(channels, row.count) {
                    arr[[0 as NSNumber, c as NSNumber, t as NSNumber]] = NSNumber(value: row[c])
                }
            }
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "sensor_data": MLFeatureValue(multiArray: arr)
            ])
            let out = try model.prediction(from: provider)

            // Parse outputs (same as inferIfReady)
            if let ex = out.featureValue(for: "exercise_logits")?.multiArrayValue {
                let idx = argmax1D(ex)
                currentExercise = Exercise(rawValue: labelForExercise(idx)) ?? .unknown
                debugExerciseLogits = toArray(ex)
            }
            if let fatigue = out.featureValue(for: "fatigue_score")?.multiArrayValue {
                fatigueLevel = Float(truncating: fatigue[idx1D: 0])
            }
            if let rep = out.featureValue(for: "rep_probs")?.multiArrayValue {
                let mean = mean1D(rep)
                debugRepMean = mean
                if mean > 0.5 { repCount += 1 }
            }
            if let form = out.featureValue(for: "form_logits")?.multiArrayValue {
                let idx = argmax1D(form)
                formQuality = idx == 0 ? .excellent : (idx == 1 ? .needsWork : .good)
                debugFormLogits = toArray(form)
            }
        } catch {
            print("❌ Inference error: \(error)")
        }
    }

    private func labelForExercise(_ idx: Int) -> String {
        let labels = ["standing_march","arm_circles","step_touch","wall_pushup","seated_extension"]
        if idx >= 0 && idx < labels.count { return labels[idx] }
        return "unknown"
    }
}

// MARK: - MLMultiArray helpers
private extension MLMultiArray {
    subscript(idx1D idx: Int) -> NSNumber {
        // assumes 1-D array
        return self[[NSNumber(value: idx)]]
    }
}

private func argmax1D(_ a: MLMultiArray) -> Int {
    var bestIdx = 0
    var bestVal = -Float.greatestFiniteMagnitude
    for i in 0..<a.count {
        let v = Float(truncating: a[idx1D: i])
        if v > bestVal { bestVal = v; bestIdx = i }
    }
    return bestIdx
}

private func mean1D(_ a: MLMultiArray) -> Float {
    var sum: Float = 0
    for i in 0..<a.count { sum += Float(truncating: a[idx1D: i]) }
    return sum / Float(max(1, a.count))
}

private func toArray(_ a: MLMultiArray) -> [Float] {
    let count = a.count
    var result = [Float](repeating: 0, count: count)
    let ptr = a.dataPointer.bindMemory(to: Float.self, capacity: count)
    for i in 0..<count { result[i] = ptr[i] }
    return result
}
