import Testing
import Foundation
@testable import VinylSoul

struct StatsOverviewTests {

    @Test func timelineExcludesFutureDates() {
        let result = GenerationResult(
            lyrics: "Test",
            albumTitle: "Test",
            djScript: "Test",
            recommendations: []
        )

        let calendar = Calendar.current
        let today = Date()
        let pastDate = calendar.date(byAdding: .day, value: -2, to: today)!

        let record = InspirationRecord(result: result, mood: .romantic, style: .slowJam)
        record.timestamp = pastDate

        let stats = StatsOverview.from([record])

        let hasFutureDates = stats.recentTimeline.contains { $0.date > today }
        #expect(!hasFutureDates, "Timeline should not include future dates")
    }

    @Test func timelineIncludesOnlyPastDays() {
        let result = GenerationResult(
            lyrics: "Test",
            albumTitle: "Test",
            djScript: "Test",
            recommendations: []
        )

        let calendar = Calendar.current
        let today = Date()

        // Create a record for the 1st of current month
        var firstOfMonth = calendar.dateComponents([.year, .month], from: today)
        firstOfMonth.day = 1
        let firstDay = calendar.date(from: firstOfMonth)!

        let record = InspirationRecord(result: result, mood: .romantic, style: .slowJam)
        record.timestamp = firstDay

        let stats = StatsOverview.from([record])

        let todayDay = calendar.component(.day, from: today)
        // Timeline should only have entries up to today
        let daysInTimeline = stats.recentTimeline.count
        let expectedDays = todayDay
        #expect(daysInTimeline == expectedDays,
                "Timeline should have \(expectedDays) days (1st through today), got \(daysInTimeline)")
    }
}
