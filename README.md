# GrammarMe

GrammarMe removes the copy-to-ChatGPT detour from everyday writing.

## Guiding principle

> Stay where you are writing.

The user should be able to select a draft in Slack, WhatsApp, or another macOS app, choose **Services → Format with GrammarMe**, and receive polished text back in the same field. GrammarMe must preserve meaning and voice, correct grammar and spelling, improve clarity, and avoid introducing unnecessary dashes or other stylistic flourishes.

## Primary user journey

```gherkin
Given I have selected drafted text in Slack or WhatsApp
And I have configured my OpenAI API key
When I choose "Format with GrammarMe" from Services
Then GrammarMe analyzes the selected text
And replaces the selection with corrected text
And preserves the original meaning and tone
And does not add stylistic dashes unnecessarily
```

## MVP

- A macOS menu-bar app, with no required editor window.
- A native macOS text Service named **Format with GrammarMe**.
- In-place replacement of selected text when the host supports Services.
- API-key configuration from the menu bar.
- Clear notifications for success, missing setup, and failures.
- Clipboard fallback for host apps that do not expose selected text to macOS Services.

## Development approach

Work follows specification-driven development. Describe behavior from the user journey in Given/When/Then form, encode it as an automated test, observe it fail (red), implement the smallest coherent change (green), then refactor while keeping the suite green.

## Download and install

GrammarMe requires macOS 14 or later.

1. Open the [GrammarMe Releases page](https://github.com/kelvin0722/GrammarMe/releases).
2. Download the latest `GrammarMe.zip` release asset and unzip it.
3. Drag `GrammarMe.app` into **Applications**.
4. Launch GrammarMe once. If macOS asks for confirmation, Control-click the app, choose **Open**, then confirm **Open**.
5. Left-click the GrammarMe menu-bar icon, open **Settings**, enter an OpenAI API key, and choose **Save**.

If the Releases page has no downloadable app yet, build it locally using the instructions below. Do not download builds from unofficial mirrors.

## Build from source

Requirements: macOS 14 or later, Git, and Xcode 26.6 or later.

### Xcode

1. Clone this repository:

   ```sh
   git clone https://github.com/kelvin0722/GrammarMe.git
   cd GrammarMe
   ```

2. Open `GrammarMe.xcodeproj` in Xcode.
3. Select the **GrammarMe** scheme and **My Mac** destination.
4. In **Signing & Capabilities**, select your Apple Development team if Xcode requests one.
5. Press **Run**. Xcode builds and launches the menu-bar app.

### Command line

After selecting a signing team in Xcode once, build a Release app with:

```sh
xcodebuild \
  -project GrammarMe.xcodeproj \
  -scheme GrammarMe \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build

ditto .build/Build/Products/Release/GrammarMe.app /Applications/GrammarMe.app
open /Applications/GrammarMe.app
```

Run the automated behavior tests with:

```sh
xcodebuild test \
  -project GrammarMe.xcodeproj \
  -scheme GrammarMe \
  -destination 'platform=macOS'
```

## Configure and use

1. Left-click the GrammarMe icon in the menu bar, open **Settings**, and save an OpenAI API key.
2. Select text in a macOS app and choose **Services → Format with GrammarMe** from its context menu.
3. Wait for the small **Formatting…** indicator; GrammarMe replaces the selected text when the response completes.
4. If a host does not expose Services, copy the text, left-click GrammarMe in the menu bar, and choose **Format Clipboard**.

If the Service is missing, launch GrammarMe once so macOS can register it, then enable it in **System Settings → Keyboard → Keyboard Shortcuts → Services → Text**. A keyboard shortcut can be assigned there as well. Some Electron-based fields do not expose macOS Services; use **Format Clipboard** from the menu-bar icon in those fields.

## Response-time strategy

The formatting request uses `gpt-5.6-luna`, no reasoning pass, low output verbosity, and a strict one-field response schema. This keeps generation focused on returning the replacement text. GrammarMe also fails a stalled request after 30 seconds so the user receives actionable feedback instead of waiting indefinitely.

Streaming is not used for in-place replacement: the host app's selection can only be safely replaced after the complete corrected text has arrived.

## Privacy and security

Text is sent to OpenAI only after the user invokes the Service. The MVP stores the API key in `UserDefaults` for speed; moving it to Keychain is required before a production release.
