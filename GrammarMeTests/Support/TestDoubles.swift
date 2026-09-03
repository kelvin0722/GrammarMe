import AppKit
import Foundation
import XCTest
@testable import GrammarMe

struct StubFormatter: TextFormatting {
    let result: Result<String, Error>
    func format(_ text: String, apiKey: String) async throws -> String { try result.get() }
}

struct StatusObservingFormatter: TextFormatting {
    let operation: @Sendable () -> String
    func format(_ text: String, apiKey: String) async throws -> String { operation() }
}

@MainActor
final class ClipboardSpy: ClipboardManaging {
    var text: String?
    init(text: String?) { self.text = text }
    func readText() -> String? { text }
    func writeText(_ text: String) { self.text = text }
}

final class ThreadSafeValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: Value?
    var value: Value? { lock.withLock { storedValue } }
    func set(_ value: Value) { lock.withLock { storedValue = value } }
}

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do { _ = try await expression(); XCTFail("Expected an error") }
    catch { errorHandler(error) }
}
