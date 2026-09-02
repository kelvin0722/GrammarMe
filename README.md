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

## Running the MVP

1. Build and run the `GrammarMe` scheme on **My Mac**.
2. Left-click the GrammarMe icon in the menu bar, open **Settings**, and save an OpenAI API key.
3. Select text in a macOS app and choose **Services → Format with GrammarMe** from its context menu.
4. If a host does not expose Services, copy the text, left-click GrammarMe in the menu bar, and choose **Format Clipboard**.

If the Service is missing, launch GrammarMe once so macOS can register it, then enable it in **System Settings → Keyboard → Keyboard Shortcuts → Services → Text**. A keyboard shortcut can be assigned there as well. Some Electron-based fields do not expose macOS Services; use **Format Clipboard** from the menu-bar icon in those fields.

## Privacy and security

Text is sent to OpenAI only after the user invokes the Service. The MVP stores the API key in `UserDefaults` for speed; moving it to Keychain is required before a production release.
