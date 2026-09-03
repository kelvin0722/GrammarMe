---
name: grammarme-code-conventions
description: Apply GrammarMe-specific Swift, SwiftUI, concurrency, architecture, and BDD test conventions when implementing or reviewing code in this repository.
---

# GrammarMe Code Conventions

Preserve the menu-bar app's core promise: format selected text in place, preserve meaning and voice, and avoid unsolicited stylistic changes.

## Architecture

- Keep SwiftUI views declarative. Views render state and forward user actions; put orchestration in an `@MainActor @Observable` model.
- Keep domain protocols independent of OpenAI, Keychain, pasteboards, notifications, and AppKit.
- Put macOS integrations behind small injectable protocols. Keep AppKit at platform boundaries.
- Inject dependencies through initializers. Production defaults may be convenient, but tests must be able to supply deterministic doubles.
- Represent mutually exclusive loading, success, and failure states with an enum rather than overlapping booleans and optional messages.
- Never persist credentials in `UserDefaults`; use `APIKeyStoring` and propagate Keychain errors accurately.

## Swift and concurrency

- Prefer value types and immutable state. Name APIs using Swift API Design Guidelines and lower camel case.
- Treat warnings as defects. Do not add `@unchecked Sendable`, `nonisolated(unsafe)`, detached tasks, or nested run loops without documenting the invariant and covering it with a focused test.
- Keep AppKit, pasteboard, and observable UI mutations on the main actor. Do network and storage work without blocking the main actor.
- Preserve cancellation and surface actionable `LocalizedError` messages at user-facing boundaries.

## Tests

- Work red, green, refactor. Express behavior as Given/When/Then test names.
- Organize tests by subject under `Domain`, `Features`, `Networking`, and `Platform`; put reusable doubles in `Support`.
- Test observable outcomes, payload contracts, error propagation, and cancellation. Avoid tests that only restate implementation text unless the text is an external prompt or registration contract.
- Keep network stubs request-scoped and safe for parallel execution. Never share an unprotected mutable global handler.
- Run the unit suite and `git diff --check` before handing off a change.

Use `rg` for repository discovery and `xcodebuild` with a disposable DerivedData directory for verification. Do not commit build products, credentials, DerivedData, or `.DS_Store` files.
