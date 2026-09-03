import XCTest
@testable import GrammarMe

@MainActor
final class GrammarMeModelTests: XCTestCase {
    func testGivenClipboardTextWhenFormattingSucceedsThenClipboardAndPhaseAreUpdated() async {
        let clipboard = ClipboardSpy(text: "This are wrong.")
        let useCase = FormatSelectedText(formatter: StubFormatter(result: .success("This is right.")), apiKey: { "key" })
        let subject = GrammarMeModel(useCase: useCase, clipboard: clipboard)
        await subject.formatClipboard()
        XCTAssertEqual(clipboard.text, "This is right.")
        XCTAssertEqual(subject.phase, .success("Formatted text copied."))
    }

    func testGivenEmptyClipboardWhenFormattingThenFailureIsPresented() async {
        let subject = GrammarMeModel(useCase: FormatSelectedText(formatter: StubFormatter(result: .success("unused")), apiKey: { "key" }), clipboard: ClipboardSpy(text: nil))
        await subject.formatClipboard()
        XCTAssertEqual(subject.phase, .failure("Copy some text first."))
    }
}
