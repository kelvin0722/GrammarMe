import AppKit
import XCTest
@testable import GrammarMe

final class GrammarMeServiceJourneyTests: XCTestCase {
    @MainActor
    func testGivenSelectedTextWhenServiceRunsThenItShowsProgressAndReplacesTheSelection() throws {
        UserDefaults.standard.removeObject(forKey: "lastServiceStatus")
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("This are a draft.", forType: .string)
        let observedStatus = ThreadSafeValue<String?>()
        let useCase = FormatSelectedText(
            formatter: StatusObservingFormatter {
                observedStatus.set(UserDefaults.standard.string(forKey: "lastServiceStatus"))
                return "This is a draft."
            },
            apiKey: { "test-key" }
        )
        let subject = GrammarMeServiceProvider(useCase: useCase)
        var serviceError: NSString?

        subject.formatText(pasteboard, userData: nil, error: &serviceError)

        XCTAssertNil(serviceError)
        XCTAssertEqual(observedStatus.value, "Formatting selected text…")
        XCTAssertEqual(pasteboard.string(forType: .string), "This is a draft.")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "lastServiceStatus"), "Formatting complete.")
    }

    func testGivenGrammarMeIsInstalledThenFormatServiceIsAdvertised() throws {
        let services = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "NSServices") as? [[String: Any]])
        let menuItem = services.first?["NSMenuItem"] as? [String: String]

        XCTAssertEqual(menuItem?["default"], "Format with GrammarMe")
        XCTAssertEqual(services.first?["NSMessage"] as? String, "formatText")
        XCTAssertEqual(services.first?["NSTimeout"] as? String, "60000")
    }

    func testGivenSelectedTextAndSavedKeyWhenFormattingThenCorrectedTextIsReturned() async throws {
        let formatter = StubFormatter(result: .success("I have gone home."))
        let subject = FormatSelectedText(formatter: formatter, apiKey: { "test-key" })

        let result = try await subject.run("I has went home.")

        XCTAssertEqual(result, "I have gone home.")
    }

    func testGivenNoSelectedTextWhenFormattingThenActionableErrorIsReturned() async {
        let subject = FormatSelectedText(formatter: StubFormatter(result: .success("unused")), apiKey: { "test-key" })

        await XCTAssertThrowsErrorAsync(try await subject.run("   ")) { error in
            XCTAssertEqual(error as? FormattingJourneyError, .noSelectedText)
        }
    }

    func testGivenNoSavedKeyWhenFormattingThenSettingsErrorIsReturned() async {
        let subject = FormatSelectedText(formatter: StubFormatter(result: .success("unused")), apiKey: { "" })

        await XCTAssertThrowsErrorAsync(try await subject.run("Please format me.")) { error in
            XCTAssertEqual(error as? FormattingJourneyError, .missingAPIKey)
        }
    }

    func testGivenFormatterAddsEmDashesWhenOriginalHasNoneThenTheyAreRemoved() async throws {
        let formatter = StubFormatter(result: .success("Clear writing — without extra punctuation."))
        let subject = FormatSelectedText(formatter: formatter, apiKey: { "test-key" })

        let result = try await subject.run("Clear writing without extra punctuation.")

        XCTAssertEqual(result, "Clear writing without extra punctuation.")
    }
}

private struct StubFormatter: TextFormatting {
    let result: Result<String, Error>
    func format(_ text: String, apiKey: String) async throws -> String { try result.get() }
}

private struct StatusObservingFormatter: TextFormatting {
    let operation: @Sendable () -> String
    func format(_ text: String, apiKey: String) async throws -> String { operation() }
}

private nonisolated final class ThreadSafeValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: Value?
    var value: Value? { lock.withLock { storedValue } }
    func set(_ value: Value) { lock.withLock { storedValue = value } }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do { _ = try await expression(); XCTFail("Expected an error") }
    catch { errorHandler(error) }
}
