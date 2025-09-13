# sesame-conversational-coach-new

iOS 15+ SwiftUI app scaffold for the Chimera Ascendant PoC.

- Phone-only, iPhone target, bundle ID: `com.chimera-ascendant.poc`
- UnifiedAudioEngine: single-owner .playAndRecord, energy-threshold VAD, barge-in
- IntentClassifier: rules-first, ML stub optional
- PerceptionEngine: Core ML integration (model to be added)
- CognitiveCore: rules subset (sanity, prioritization, core commands/questions, cue budget)

## Build & Run

1) Generate Xcode project with XcodeGen (recommended)

```
brew install xcodegen   # if not installed
xcodegen generate
open ChimeraCoach.xcodeproj
```

2) Configure the Cognitive endpoint (optional)

The app defaults to `http://localhost:8080` for the Cognitive Core FastAPI server. Run the server from `chimera-infra-new`:

```
cd ../chimera-infra-new
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

3) Permissions

- Microphone and Speech Recognition usage descriptions are included in `App/Info.plist`.

4) Notes

- The perception path includes a placeholder `PerceptionEngine` using mock frames until the Core ML model is exported from `quantumleap-imu-engine` and embedded.
- Endpoint auth is optional (disabled if `CHIMERA_API_TOKEN` not set on the server).
