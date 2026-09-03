import XCTest
@testable import GrammarMe

@MainActor
final class GrammarMeModelTests: XCTestCase {
    private struct CredentialError: LocalizedError {
        var errorDescription: String? { "Keychain is unavailable." }
    }

    func testGivenCredentialStoreFailureWhenModelLoadsThenFailureIsPresented() {
        let store = APIKeyStoreSpy()
        store.loadError = CredentialError()
        let subject = GrammarMeModel(apiKeyStore: store, formatter: StubFormatter(result: .success("unused")), clipboard: ClipboardSpy(text: nil))
        XCTAssertFalse(subject.hasAPIKey)
        XCTAssertEqual(subject.phase, .failure("Keychain is unavailable."))
    }

    func testGivenCredentialStoreFailureWhenFormattingThenFailureIsPreserved() async {
        let store = APIKeyStoreSpy(key: "key")
        let subject = GrammarMeModel(apiKeyStore: store, formatter: StubFormatter(result: .success("unused")), clipboard: ClipboardSpy(text: "Text"))
        store.loadError = CredentialError()
        await subject.formatClipboard()
        XCTAssertEqual(subject.phase, .failure("Keychain is unavailable."))
    }

    func testGivenSavedCredentialWhenModelLoadsThenAPIKeyIsConfigured() {
        let store = APIKeyStoreSpy(key: "saved-key")
        let subject = GrammarMeModel(apiKeyStore: store, formatter: StubFormatter(result: .success("unused")), clipboard: ClipboardSpy(text: nil))
        XCTAssertTrue(subject.hasAPIKey)
        XCTAssertEqual(subject.apiKeyForEditing(), "saved-key")
    }

    func testGivenWhitespacePaddedCredentialWhenSavingThenTrimmedKeyIsStored() {
        let store = APIKeyStoreSpy()
        let subject = GrammarMeModel(apiKeyStore: store, formatter: StubFormatter(result: .success("unused")), clipboard: ClipboardSpy(text: nil))
        XCTAssertTrue(subject.saveAPIKey("  secret-key\n"))
        XCTAssertEqual(try store.load(), "secret-key")
        XCTAssertTrue(subject.hasAPIKey)
        XCTAssertEqual(subject.phase, .success("API key saved."))
    }

    func testGivenClipboardTextWhenFormattingSucceedsThenClipboardAndPhaseAreUpdated() async {
        let clipboard = ClipboardSpy(text: "This are wrong.")
        let subject = GrammarMeModel(apiKeyStore: APIKeyStoreSpy(key: "key"), formatter: StubFormatter(result: .success("This is right.")), clipboard: clipboard)
        await subject.formatClipboard()
        XCTAssertEqual(clipboard.text, "This is right.")
        XCTAssertEqual(subject.phase, .success("Formatted text copied."))
    }

    func testGivenEmptyClipboardWhenFormattingThenFailureIsPresented() async {
        let subject = GrammarMeModel(apiKeyStore: APIKeyStoreSpy(key: "key"), formatter: StubFormatter(result: .success("unused")), clipboard: ClipboardSpy(text: nil))
        await subject.formatClipboard()
        XCTAssertEqual(subject.phase, .failure("Copy some text first."))
    }
}
