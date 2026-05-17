import Foundation
import SwiftUI

@Observable
final class PlaybackViewModel {
    var displayedText: String = ""
    var isComplete = false

    private var timer: Timer?
    private var fullText: String = ""
    private var currentIndex: Int = 0

    func startTypewriter(text: String, interval: TimeInterval = 0.05) {
        reset()
        fullText = text
        currentIndex = 0

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard self.currentIndex < self.fullText.count else {
                timer.invalidate()
                self.timer = nil
                self.isComplete = true
                return
            }
            let idx = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentIndex)
            self.displayedText = String(self.fullText[..<self.fullText.index(after: idx)])
            self.currentIndex += 1
        }
    }

    func skipToEnd() {
        timer?.invalidate()
        timer = nil
        displayedText = fullText
        isComplete = true
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        displayedText = ""
        isComplete = false
        currentIndex = 0
    }
}
