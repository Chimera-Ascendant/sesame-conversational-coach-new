# TASK_BACKLOG (sesame-conversational-coach-new)

version: 1
updated: 2025-09-12

```yaml
repo: sesame-conversational-coach-new
sprint:
  name: iOS PoC App v0.1
  dates: [2025-09-13, 2025-09-20]
owners:
  - jonathan
labels:
  - ios
  - swiftui
  - audio
  - coreml
  - ui

tasks:
  - id: perception_integration
    title: Integrate Core ML model and drive UI state
    status: completed
    priority: high
    labels: [coreml]
    acceptance_criteria:
      - Model loads from bundle and runs inference with [T,8] input
      - UI shows exercise, reps, fatigue

  - id: asr_streaming
    title: On-device SFSpeechRecognizer streaming (single utterance)
    status: completed
    priority: high
    labels: [audio]
    acceptance_criteria:
      - Works on-device with privacy permissions
      - Results pipe into CognitiveCore

  - id: settings_panel
    title: Settings screen for endpoint URL/token
    status: completed
    priority: medium
    labels: [ui]
    acceptance_criteria:
      - Editable URL/token persisted in UserDefaults
      - CognitiveClient updates without rebuild

  - id: device_build
    title: Device signing and minimal release notes
    status: pending
    priority: medium
    labels: [ios]
    acceptance_criteria:
      - Archive builds for device; README updated
```
