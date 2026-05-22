import Foundation

struct StatsOverview {
    let totalGenerations: Int
    let monthlyGenerations: Int
    let topStyle: StyleTag?
    let topMood: Mood?
    let styleDistribution: [StyleTag: Int]
    let moodDistribution: [Mood: Int]
    let recentTimeline: [(date: Date, count: Int)]

    static func from(_ records: [InspirationRecord]) -> StatsOverview {
        let total = records.count
        let calendar = Calendar.current
        let thisMonth = calendar.component(.month, from: Date())
        let thisYear = calendar.component(.year, from: Date())

        let monthly = records.filter {
            let m = calendar.component(.month, from: $0.timestamp)
            let y = calendar.component(.year, from: $0.timestamp)
            return m == thisMonth && y == thisYear
        }

        var styleDist: [StyleTag: Int] = [:]
        var moodDist: [Mood: Int] = [:]
        for r in records {
            if let style = StyleTag(rawValue: r.styleTagRaw) {
                styleDist[style, default: 0] += 1
            }
            if let mood = Mood(rawValue: r.moodRaw) {
                moodDist[mood, default: 0] += 1
            }
        }

        let topStyle = styleDist.max(by: { $0.value < $1.value })?.key
        let topMood = moodDist.max(by: { $0.value < $1.value })?.key

        var timeline: [(Date, Int)] = []
        let now = Date()
        if let range = calendar.range(of: .day, in: .month, for: now) {
            for day in range {
                var comps = calendar.dateComponents([.year, .month], from: now)
                comps.day = day
                if let date = calendar.date(from: comps), date <= now {
                    let count = monthly.filter {
                        calendar.isDate($0.timestamp, inSameDayAs: date)
                    }.count
                    timeline.append((date, count))
                }
            }
        }

        return StatsOverview(
            totalGenerations: total,
            monthlyGenerations: monthly.count,
            topStyle: topStyle,
            topMood: topMood,
            styleDistribution: styleDist,
            moodDistribution: moodDist,
            recentTimeline: timeline
        )
    }
}
