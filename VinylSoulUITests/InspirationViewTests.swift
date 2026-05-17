import XCTest

final class InspirationViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMoodSelection() throws {
        let romanticButton = app.buttons.element(
            matching: NSPredicate(format: "label CONTAINS %@", "浪漫")
        )
        XCTAssertTrue(romanticButton.waitForExistence(timeout: 3))
        romanticButton.tap()
    }

    func testKeywordInput() throws {
        let textField = app.textFields["输入关键词，如：雨夜、末班车..."]
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText("雨夜, 末班车")
    }

    func testGenerateButtonDisabledWhenEmpty() throws {
        let button = app.buttons["生成灵感"]
        XCTAssertTrue(button.exists)
        XCTAssertFalse(button.isEnabled)
    }

    func testTabNavigation() throws {
        app.tabBars.buttons["唱片架"].tap()
        XCTAssertTrue(app.staticTexts["唱片架"].exists)

        app.tabBars.buttons["创作"].tap()
        XCTAssertTrue(app.staticTexts["VinylSoul"].exists)

        app.tabBars.buttons["正在播放"].tap()
        let emptyText = app.staticTexts.element(
            matching: NSPredicate(format: "label CONTAINS %@", "还没有灵感")
        )
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3))
    }
}
