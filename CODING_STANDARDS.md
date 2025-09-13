# CODING_STANDARDS (sesame-conversational-coach-new)

## Swift
- Swift 5.9+, iOS 15+ minimum
- Prefer SwiftUI for UI; separate concerns by module (Audio, Perception, Cognitive, UI)
- Use `@StateObject`/`@ObservedObject` appropriately; avoid heavy work in `init`—prefer `onAppear`
- Keep imports minimal per file; no force unwraps unless justified

## Audio (AVFoundation / Speech)
- Single owner model for audio session to avoid conflicts
- Respect turn-based audio (listening vs speaking) states
- Request permissions at runtime and handle denial gracefully

## Core ML
- Bundle `.mlpackage` under `Models/` via project.yml resources
- Validate I/O shapes and run inference off main thread when heavy

## Networking
- Use `URLSession` with JSON codable request/response structs
- Bearer token optional; never hardcode secrets

## Commits & PRs
- Conventional commits (feat, fix, chore, docs, refactor, test, ci)
- Keep PRs small, include steps to test

## CI
- Use XcodeGen to generate project
- Build for iOS Simulator with `CODE_SIGNING_ALLOWED=NO`
