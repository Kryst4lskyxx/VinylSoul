import SwiftUI
import Charts

struct StatsView: View {
    let viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss

    private var stats: StatsOverview {
        viewModel.statsOverview()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    overviewCards
                    styleChart
                    moodChart
                    timelineSection
                }
                .padding()
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "总生成", value: "\(stats.totalGenerations)")
            StatCard(title: "本月生成", value: "\(stats.monthlyGenerations)")
        }
    }

    @ViewBuilder
    private var styleChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格分布")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.styleDistribution.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Chart {
                    ForEach(
                        Array(stats.styleDistribution),
                        id: \.key
                    ) { style, count in
                        BarMark(
                            x: .value("次数", count),
                            y: .value("风格", style.rawValue)
                        )
                        .foregroundStyle(Color(hex: "#E8A850").gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(stats.styleDistribution.count * 40 + 20))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情分布")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.moodDistribution.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Chart {
                    ForEach(
                        Array(stats.moodDistribution),
                        id: \.key
                    ) { mood, count in
                        BarMark(
                            x: .value("次数", count),
                            y: .value("心情", mood.rawValue)
                        )
                        .foregroundStyle(Color.purple.opacity(0.6).gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(stats.moodDistribution.count * 40 + 20))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月时间线")
                .font(.headline)
                .foregroundStyle(.secondary)

            if stats.recentTimeline.allSatisfy({ $0.count == 0 }) {
                Text("本月暂无记录")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(stats.recentTimeline, id: \.date) { item in
                    HStack {
                        Text(item.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if item.count > 0 {
                            HStack(spacing: 4) {
                                ForEach(0..<min(item.count, 10), id: \.self) { _ in
                                    Circle()
                                        .fill(Color(hex: "#E8A850"))
                                        .frame(width: 8, height: 8)
                                }
                                Text("\(item.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color(hex: "#E8A850"))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
