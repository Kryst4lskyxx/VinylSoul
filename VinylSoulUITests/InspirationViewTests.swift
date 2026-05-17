import XCTest

final class InspirationViewTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMoodSelection() throws {
        let romanticButton = app.staticTexts["浪漫"]
        XCTAssertTrue(romanticButton.exists)
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
        // Button should be disabled with empty keywords
        XCTAssertFalse(button.isEnabled)
    }

    func testTabNavigation() throws {
        app.tabBars.buttons["唱片架"].tap()
        XCTAssertTrue(app.staticTexts["唱片架"].exists)

        app.tabBars.buttons["创作"].tap()
        XCTAssertTrue(app.staticTexts["VinylSoul"].exists)

        app.tabBars.buttons["正在播放"].tap()
        XCTAssertTrue(app.staticTexts["还没有灵感"].exists)
    }
}
