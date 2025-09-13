import SwiftUI

struct TelemetryView: View {
    @ObservedObject var engine: PerceptionEngine

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Exercise Logits")) {
                    ForEach(Array(engine.debugExerciseLogits.enumerated()), id: \.offset) { (i, v) in
                        HStack {
                            Text("Class \(i)")
                            Spacer()
                            Text(String(format: "%.3f", v))
                                .monospacedDigit()
                        }
                    }
                }
                Section(header: Text("Form Logits")) {
                    ForEach(Array(engine.debugFormLogits.enumerated()), id: \.offset) { (i, v) in
                        HStack {
                            Text("Form \(i)")
                            Spacer()
                            Text(String(format: "%.3f", v))
                                .monospacedDigit()
                        }
                    }
                }
                Section(header: Text("Rep Probability Mean")) {
                    HStack {
                        Text("Mean")
                        Spacer()
                        Text(String(format: "%.3f", engine.debugRepMean))
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Model Telemetry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TelemetryView_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryView(engine: PerceptionEngine())
    }
}
