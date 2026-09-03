# Apple versioning and distribution

GrammarMe maps versions through Xcode build settings:

- `MARKETING_VERSION` expands into `CFBundleShortVersionString` and must equal the SemVer release value, for example `1.0.0`.
- `CURRENT_PROJECT_VERSION` expands into `CFBundleVersion` and must be a monotonically increasing positive integer.
- `VERSIONING_SYSTEM = apple-generic` enables Apple Generic Versioning and compatibility with `xcrun agvtool`.

Use `xcrun agvtool what-marketing-version` and `xcrun agvtool what-version` as diagnostics, but validate the resolved target settings with `xcodebuild -showBuildSettings` and validate the archived app's `Info.plist`. Modern generated test-target plists can make `agvtool` output noisy; the resolved app target and archive are authoritative.

Apple references:

- [Xcode command-line tool reference](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference)
- [Automating versions with agvtool](https://developer.apple.com/library/archive/qa/qa1827/_index.html)
- [Creating distribution-signed code for macOS](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/)
- [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

For direct distribution, archive with `xcodebuild archive`, export using Developer ID settings, notarize with `notarytool`, staple the ticket, and verify with both `codesign` and Gatekeeper's `spctl`.
