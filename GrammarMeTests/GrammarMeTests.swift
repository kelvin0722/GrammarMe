import AppKit
import XCTest
@testable import GrammarMe

final class GrammarMeServiceJourneyTests: XCTestCase {
    func testGivenTextToFormatWhenOpenAIRequestIsSentThenItUsesLatencyOptimizedSettings() async throws {
        let capturedBody = ThreadSafeValue<[String: Any]>()
        URLProtocolStub.handler = { request in
            let data = try request.bodyData()
            capturedBody.set(try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any]))
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let payload = #"{"output":[{"content":[{"type":"output_text","text":"{\"formattedText\":\"This is correct.\"}"}]}]}"#
            return (response, Data(payload.utf8))
        }
        defer { URLProtocolStub.handler = nil }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let formatter = OpenAITextFormatter(session: URLSession(configuration: configuration))

        let result = try await formatter.format("This are correct.", apiKey: "test-key")

        let body = try XCTUnwrap(capturedBody.value)
        XCTAssertEqual(result, "This is correct.")
        XCTAssertEqual(body["model"] as? String, "gpt-5.6-luna")
        XCTAssertEqual((body["reasoning"] as? [String: Any])?["effort"] as? String, "none")
        XCTAssertEqual((body["text"] as? [String: Any])?["verbosity"] as? String, "low")
    }

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

private extension URLRequest {
    func bodyData() throws -> Data {
        if let httpBody { return httpBody }
        let stream = try XCTUnwrap(httpBodyStream)
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { throw try XCTUnwrap(stream.streamError) }
            if count == 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (response, data) = try XCTUnwrap(Self.handler)(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
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
