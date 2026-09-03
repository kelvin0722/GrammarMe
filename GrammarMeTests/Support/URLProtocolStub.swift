import Foundation
import XCTest

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    private static let lock = NSLock()
    private nonisolated(unsafe) static var handlers: [String: Handler] = [:]
    private static let header = "X-GrammarMe-Test-ID"

    static func session(handler: @escaping Handler) -> URLSession {
        let identifier = UUID().uuidString
        lock.withLock { handlers[identifier] = handler }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        configuration.httpAdditionalHeaders = [header: identifier]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: header) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let identifier = try XCTUnwrap(request.value(forHTTPHeaderField: Self.header))
            let handler = try XCTUnwrap(Self.lock.withLock { Self.handlers[identifier] })
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLRequest {
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
