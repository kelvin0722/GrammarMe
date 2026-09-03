import XCTest

final class ServiceRegistrationTests: XCTestCase {
    func testGivenGrammarMeIsInstalledThenFormatServiceIsAdvertised() throws {
        let services = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "NSServices") as? [[String: Any]])
        let menuItem = services.first?["NSMenuItem"] as? [String: String]
        XCTAssertEqual(menuItem?["default"], "Format with GrammarMe")
        XCTAssertEqual(services.first?["NSMessage"] as? String, "formatText")
        XCTAssertEqual(services.first?["NSTimeout"] as? String, "60000")
    }
}
