import SwiftUI

struct ChimeraWorkoutView: View {
    @StateObject private var audio = UnifiedAudioEngine()
    @StateObject private var perception = PerceptionEngine()
    @State private var core: CognitiveCore?

    @State private var isActive: Bool = false
    @State private var lastVoice: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Chimera AI Coach")
                .font(.largeTitle)
                .bold()

            // Status
            VStack(spacing: 8) {
                Text("Exercise: \(perception.currentExercise.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)")
                Text("Reps: \(perception.repCount)")
                Text("Fatigue: \(String(format: "%.2f", perception.fatigueLevel))")
                Text("Last Cue: \(core?.lastCoachingCue ?? "")")
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 16) {
                if !isActive {
                    Button("Start") { startWorkout() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Pause") { core?.pauseWorkout(); isActive = false }
                        .buttonStyle(.bordered)
                    Button("End") { core?.endWorkout(); isActive = false }
                        .buttonStyle(.bordered)
                }
            }

            Button("Voice Command") {
                audio.startListening { recognized in
                    lastVoice = recognized ?? ""
                    core?.processVoiceCommand(recognized ?? "")
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .onAppear {
            core = CognitiveCore(perception: perception, audio: audio)
        }
    }

    private func startWorkout() {
        isActive = true
        core?.startWorkout()
    }
}

struct ChimeraWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        ChimeraWorkoutView()
    }
}
