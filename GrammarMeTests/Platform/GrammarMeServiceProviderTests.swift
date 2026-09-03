import AppKit
import XCTest
@testable import GrammarMe

final class GrammarMeServiceProviderTests: XCTestCase {
    @MainActor
    func testGivenSelectedTextWhenServiceRunsThenItShowsProgressAndReplacesSelection() throws {
        UserDefaults.standard.removeObject(forKey: AppSettings.lastServiceStatus)
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("This are a draft.", forType: .string)
        let observedStatus = ThreadSafeValue<String?>()
        let useCase = FormatSelectedText(formatter: StatusObservingFormatter {
            observedStatus.set(UserDefaults.standard.string(forKey: AppSettings.lastServiceStatus))
            return "This is a draft."
        }, apiKey: { "test-key" })
        let subject = GrammarMeServiceProvider(useCase: useCase)
        var serviceError: NSString?
        subject.formatText(pasteboard, userData: nil, error: &serviceError)
        XCTAssertNil(serviceError)
        XCTAssertEqual(observedStatus.value, "Formatting selected text…")
        XCTAssertEqual(pasteboard.string(forType: .string), "This is a draft.")
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppSettings.lastServiceStatus), "Formatting complete.")
    }
}
