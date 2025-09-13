import SwiftUI

struct ChimeraWorkoutView: View {
    @StateObject private var audio = UnifiedAudioEngine()
    @StateObject private var perception = PerceptionEngine()
    @StateObject private var settings = SettingsStore()
    @State private var core: CognitiveCore?

    @State private var isActive: Bool = false
    @State private var lastVoice: String = ""
    @State private var showSettings: Bool = false
    @State private var showTelemetry: Bool = false

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
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.bordered)
                Button {
                    showTelemetry = true
                } label: {
                    Image(systemName: "waveform.path.ecg")
                }
                .buttonStyle(.bordered)
            }

            Button("Voice Command") {
                audio.transcribeOnce { recognized in
                    let text = recognized ?? ""
                    lastVoice = text
                    core?.processVoiceCommand(text)
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .onAppear {
            let client = CognitiveClient(baseURL: URL(string: settings.baseURLString)!, bearerToken: settings.token)
            settings.apply(to: client)
            core = CognitiveCore(perception: perception, audio: audio, client: client)
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            if let core = core {
                let client = CognitiveClient(baseURL: URL(string: settings.baseURLString)!, bearerToken: settings.token)
                settings.apply(to: client)
                core.updateClient(client)
            }
        }) {
            SettingsView(store: settings)
        }
        .sheet(isPresented: $showTelemetry) {
            TelemetryView(engine: perception)
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
