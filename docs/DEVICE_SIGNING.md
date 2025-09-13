# Device Signing Instructions (iOS)

This app targets iOS 15+ and uses XcodeGen for project generation.

## Prerequisites
- Xcode 16+
- Apple Developer account (Team ID)
- An iPhone device connected and trusted

## Steps
1. Generate the Xcode project (if not already):
   ```bash
   xcodegen generate
   open ChimeraCoach.xcodeproj
   ```
2. Select the `ChimeraCoach` target.
3. Under Signing & Capabilities:
   - Team: select your Apple Developer Team
   - Bundle Identifier: ensure it is unique for your team (e.g., `com.chimera-ascendant.poc` or add a suffix)
   - Signing: enable automatic signing
4. Connect your device and select it as the run destination.
5. Build & Run (Cmd+R).

## Permissions
- Microphone (NSMicrophoneUsageDescription)
- Speech Recognition (NSSpeechRecognitionUsageDescription)

These are already included in `App/Info.plist`.

## Troubleshooting
- If signing fails due to provisioning profiles:
  - Ensure the bundle ID is unique under your account
  - Clean build folder (Shift+Cmd+K)
  - Quit and reopen Xcode if needed
- If app fails to install due to trust issues:
  - On the device: Settings → General → VPN & Device Management → Trust your developer profile

## Notes
- The app bundles a Core ML model at `Models/ChimeraPerception.mlpackage`.
- To update the endpoint URL or bearer token at runtime, open the in-app Settings (gear icon).
