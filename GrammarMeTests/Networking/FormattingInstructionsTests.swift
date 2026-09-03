import XCTest
@testable import GrammarMe

final class FormattingInstructionsTests: XCTestCase {
    func testGivenFormattingInstructionsThenTheyExplicitlyCoverSpellingAndGrammar() {
        XCTAssertTrue(grammarMeFormattingInstructions.contains("Correct every spelling error"))
        XCTAssertTrue(grammarMeFormattingInstructions.contains("Correct every grammatical error"))
        XCTAssertTrue(grammarMeFormattingInstructions.contains("I recieve teh message."))
        XCTAssertTrue(grammarMeFormattingInstructions.contains("I receive the message."))
        XCTAssertTrue(grammarMeFormattingInstructions.contains("She don't likes it."))
        XCTAssertTrue(grammarMeFormattingInstructions.contains("She doesn't like it."))
    }
}
