import Security
import XCTest
@testable import GrammarMe

final class APIKeyStoreTests: XCTestCase {
    func testGivenCorruptedKeychainDataWhenLoadingThenInvalidDataErrorIsReturned() throws {
        let service = "GrammarMeTests.\(UUID().uuidString)"
        let account = "corrupted-key"
        let subject = KeychainAPIKeyStore(service: service, account: account, legacyDefaultsKey: service)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data([0xFF])
        ]
        XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecSuccess)
        defer { try? subject.delete() }

        XCTAssertThrowsError(try subject.load()) { error in
            guard case APIKeyStoreError.invalidData = error else {
                return XCTFail("Expected invalidData, got \(error)")
            }
        }
    }
}
