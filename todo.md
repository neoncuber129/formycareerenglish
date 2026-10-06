# TODO: Fix GitHub Actions Workflow to Build IPA

- [x] Analyze current workflows and iOS project structure in `apps/mobile` and `apps/desktop`
- [x] Create/Update GitHub Actions workflow for building iOS IPA
  - [x] Support workflow_dispatch with options (app target: mobile vs desktop, build type)
  - [x] Setup Flutter, Java, Xcode environment properly on macOS runner
  - [x] Handle Flutter dependencies and CocoaPods
  - [x] Build iOS release without code signing blockers (`--no-codesign`)
  - [x] Package `Runner.app` into a ready-to-install/sideload `.ipa` file (`Payload/` zip packaging)
  - [x] Upload `.ipa` artifact with clear name and metadata
  - [x] Support optional GitHub Release attachment when a tag is pushed
- [x] Document usage and assumptions in `assumptions.md` and summary
