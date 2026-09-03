import XCTest
@testable import GrammarMe

final class FormatSelectedTextTests: XCTestCase {
    func testGivenSelectedTextAndSavedKeyWhenFormattingThenCorrectedTextIsReturned() async throws {
        let subject = FormatSelectedText(formatter: StubFormatter(result: .success("I have gone home.")), apiKey: { "test-key" })
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
        let subject = FormatSelectedText(formatter: StubFormatter(result: .success("Clear writing — without extra punctuation.")), apiKey: { "test-key" })
        let result = try await subject.run("Clear writing without extra punctuation.")
        XCTAssertEqual(result, "Clear writing without extra punctuation.")
    }
}
