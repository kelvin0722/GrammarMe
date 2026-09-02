import XCTest

final class GrammarMeMenuBarUITests: XCTestCase {
    @MainActor
    func testGivenGrammarMeIsLaunchedThenTheAgentKeepsRunningWithoutAnEditorWindow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.exists)
        XCTAssertEqual(app.windows.count, 0)
    }
}
