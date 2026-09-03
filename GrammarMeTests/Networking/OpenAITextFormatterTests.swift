import Foundation
import XCTest
@testable import GrammarMe

final class OpenAITextFormatterTests: XCTestCase {
    func testGivenTextWhenRequestIsSentThenLatencyOptimizedSettingsAreUsed() async throws {
        let capturedBody = ThreadSafeValue<[String: Any]>()
        let session = URLProtocolStub.session { request in
            capturedBody.set(try XCTUnwrap(JSONSerialization.jsonObject(with: request.bodyData()) as? [String: Any]))
            return try Self.response(for: request, status: 200, body: #"{"output":[{"content":[{"type":"output_text","text":"{\"formattedText\":\"This is correct.\"}"}]}]}"#)
        }
        let result = try await OpenAITextFormatter(session: session).format("This are correct.", apiKey: "test-key")
        let body = try XCTUnwrap(capturedBody.value)
        XCTAssertEqual(result, "This is correct.")
        XCTAssertEqual(body["model"] as? String, "gpt-5.6-luna")
        XCTAssertEqual((body["reasoning"] as? [String: Any])?["effort"] as? String, "none")
        XCTAssertEqual((body["text"] as? [String: Any])?["verbosity"] as? String, "low")
        XCTAssertEqual(body["instructions"] as? String, grammarMeFormattingInstructions)
    }

    func testGivenInvalidKeyWhenFormattingThenActionableErrorIsReturned() async {
        let session = URLProtocolStub.session { request in
            try Self.response(for: request, status: 401, body: #"{"error":{"message":"Unauthorized"}}"#)
        }
        await XCTAssertThrowsErrorAsync(try await OpenAITextFormatter(session: session).format("Text", apiKey: "bad")) { error in
            XCTAssertEqual(error.localizedDescription, "Your OpenAI API key appears to be invalid.")
        }
    }

    func testGivenMalformedResponseWhenFormattingThenAnErrorIsReturned() async {
        let session = URLProtocolStub.session { request in try Self.response(for: request, status: 200, body: "{}") }
        await XCTAssertThrowsErrorAsync(try await OpenAITextFormatter(session: session).format("Text", apiKey: "key")) { error in
            XCTAssertNotNil(error)
        }
    }

    private static func response(for request: URLRequest, status: Int, body: String) throws -> (HTTPURLResponse, Data) {
        let response = try XCTUnwrap(HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"]))
        return (response, Data(body.utf8))
    }
}
