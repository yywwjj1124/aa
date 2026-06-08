# Voxen Codex Guide

## Project

Voxen 维讯 is an iOS SwiftUI app for factory-floor multimodal incident recognition. The app focuses on live camera and microphone capture, dialect-aware speech recognition, local-first incident judgment, Agent-assisted enrichment, and status publishing for ITSM, WMS, EAM, MES, and AR inspection workflows.

GitHub remote:

- `origin`: `git@github.com:yywwjj1124/aa.git`
- Default branch: `main`

## Architecture

The project follows MVVM:

- `demo3/Models`: domain data models and shared state models.
- `demo3/ViewModels`: presentation state, capture orchestration, Agent calls, and UI actions.
- `demo3/Services`: API clients and local analysis services.
- `demo3/Views`: SwiftUI screens and reusable UI sections.
- `demo3/ContentView.swift`: app-level navigation and screen composition.
- `demo3/demo3App.swift`: SwiftUI app entry.

Keep feature code inside the closest existing module. Prefer extending current models, view models, and section views instead of adding broad new abstractions.

## Product Direction

Keep the app practical and factory-focused. Prioritize 2-3 high-value workflows:

- Live abnormality capture through camera, microphone, OCR, and speech.
- Dialect or language recognition with stable text extraction before status judgment.
- Incident publishing into the status center with clear next actions.

Avoid expanding into a large generic factory platform unless the user explicitly asks for it.

## Style

- Preserve the existing dark industrial visual style.
- Keep gray-on-dark text legible; prefer white or high-contrast secondary text.
- Use SwiftUI-native components and SF Symbols.
- Avoid changing existing UI copy, visual rhythm, or interaction logic unless required by the task.
- Keep Chinese user-facing text consistent with the existing Voxen factory scenario.

## Secrets

Never commit local API keys or credentials.

- Use `demo3/AgentSecrets.sample.plist` as the template.
- Keep real values only in `demo3/AgentSecrets.plist`.
- `demo3/AgentSecrets.plist` is intentionally ignored by Git.

Before committing, scan staged content for obvious API key patterns such as `sk-`.

## Git Workflow

Before making changes:

```sh
git status --short --branch
```

After changes:

```sh
git diff
git status --short
```

Commit focused changes with a clear message, then push:

```sh
git add .
git commit -m "Describe the change"
git push
```

Do not revert user changes unless explicitly requested.

## Build And Verification

Use Xcode for full device validation because camera, microphone, NFC, and AR need real device capabilities.

For code-level checks, prefer:

```sh
xcodebuild -project demo3.xcodeproj -scheme demo3 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

If simulator runtimes or signing are unavailable, report that clearly and still validate with static review where possible.

