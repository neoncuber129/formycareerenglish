# Assumptions

1. **Target App**: The repository contains both `apps/mobile` and `apps/desktop`. For mobile IPA builds, `apps/mobile` is the primary target by default, but the workflow supports selecting either `apps/mobile` or `apps/desktop` via `workflow_dispatch` inputs.
2. **Code Signing on GitHub Actions**: Most developers building IPAs on GitHub CI either do not store paid Apple Developer certificates/provisioning profiles in GitHub Secrets, or intend to use the IPA for sideloading (AltStore, Sideloadly, TrollStore, Scarlet) / Enterprise / Ad-hoc / Test distribution. Therefore, the workflow builds using `--no-codesign` and packages the resulting `Runner.app` into a standard, fully functional `.ipa` payload structure.
3. **Artifacts & Releases**: Built `.ipa` files are automatically archived as workflow artifacts accessible directly from GitHub Actions summary, with retention configured and optional release attachments on tag push.
