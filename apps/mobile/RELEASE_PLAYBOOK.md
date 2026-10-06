# Google Play Release Playbook

This playbook is the execution guide to publish `apps/mobile` from debug-only state to a production release on Google Play.

## 1) Build and signing baseline

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Put your upload keystore at `apps/mobile/keystore/upload-keystore.jks`.
3. Set a production `version` in `pubspec.yaml` (`x.y.z+buildNumber`).
4. Build release bundle:
   - `flutter build appbundle --release`
5. Output bundle:
   - `build/app/outputs/bundle/release/app-release.aab`

16 KB page size note:
- If you see compatibility warnings on `x86_64` emulator, validate with a physical ARM64 device.
- Release artifacts are configured for Play-targeted ABIs (`arm64-v8a`, `armeabi-v7a`).

## 2) Compliance package

Before submitting to Play Console, prepare:
- Privacy Policy URL (public HTTPS page)
- Data Safety answers (`release/play/data-safety-checklist.md`)
- Content rating answers
- Ads declaration and ad placement details

## 3) Store listing package

Prepare and review with:
- `release/play/store-listing-template.md`
- `release/play/store-assets-spec.md`
- `release/play/release-notes-template.md`

## 4) Test gates

Execute required checks in:
- `release/play/testing-smoke-checklist.md`
- `release/play/testing-closed-checklist.md`

## 5) Rollout and operations

Use rollout policy:
- `release/play/staged-rollout-runbook.md`

Track week-1 metrics:
- `release/play/post-release-kpi-dashboard.md`
