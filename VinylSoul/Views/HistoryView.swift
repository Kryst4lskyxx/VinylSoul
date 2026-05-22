import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppStore.self) private var appStore
    @State private var viewModel = HistoryViewModel()
    @State private var showStats = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterBar
                recordList
            }
            .navigationTitle("唱片架")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Color(hex: "#E8A850"))
                    }
                }
            }
            .onAppear {
                viewModel.fetch(modelContext: modelContext)
                if appStore.showStats {
                    showStats = true
                    appStore.showStats = false
                }
            }
            .sheet(isPresented: $showStats) {
                StatsView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索专辑或歌词...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.systemGray6).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            Picker("筛选", selection: $viewModel.filterMode) {
                ForEach(HistoryViewModel.FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.moodFilterOptions, id: \.self) { mood in
                        FilterChip(
                            label: mood,
                            isSelected: viewModel.selectedMoodFilters.contains(mood),
                            color: .purple
                        ) {
                            viewModel.toggleMoodFilter(mood)
                        }
                    }
                    ForEach(viewModel.styleFilterOptions, id: \.self) { style in
                        FilterChip(
                            label: style,
                            isSelected: viewModel.selectedStyleFilters.contains(style),
                            color: .orange
                        ) {
                            viewModel.toggleStyleFilter(style)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearAllFilters()
                } label: {
                    Text("清除筛选")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#E8A850"))
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var recordList: some View {
        if viewModel.filteredRecords.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: viewModel.hasActiveFilters
                      ? "magnifyingglass" : "square.stack")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text(viewModel.hasActiveFilters
                     ? "没有找到匹配的唱片" : "还没有灵感唱片，去创作一张吧 🎵")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
        } else if horizontalSizeClass == .regular {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredRecords) { record in
                        NavigationLink {
                            PastPlaybackView(record: record)
                        } label: {
                            HistoryCard(record: record)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.delete(record, modelContext: modelContext)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        } else {
            List {
                ForEach(viewModel.filteredRecords) { record in
                    NavigationLink {
                        PastPlaybackView(record: record)
                    } label: {
                        HistoryCard(record: record)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(record, modelContext: modelContext)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.delete(viewModel.filteredRecords[index], modelContext: modelContext)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color.opacity(0.3) : Color(.systemGray6).opacity(0.4))
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 0.5)
                )
        }
    }
}

struct PastPlaybackView: View {
    let record: InspirationRecord
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 40) {
                SpinningVinyl()
                    .frame(width: 300, height: 300)
                    .padding(.leading, 40)
                    .padding(.top, 32)

                ScrollView {
                    pastContent
                }
            }
            .navigationTitle(record.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { shareToolbarItem }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage { ShareSheet(items: [shareImage]) }
            }
            .onAppear { audioManager.playLoFi() }
            .onDisappear { audioManager.stopLoFi() }
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    SpinningVinyl()
                        .padding(.top, 32)
                    pastContent
                }
            }
            .navigationTitle(record.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { shareToolbarItem }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage { ShareSheet(items: [shareImage]) }
            }
            .onAppear { audioManager.playLoFi() }
            .onDisappear { audioManager.stopLoFi() }
        }
    }

    @ViewBuilder
    private var pastContent: some View {
        Text(record.albumTitle)
            .font(.title2.weight(.medium))
            .foregroundStyle(Color(hex: "#E8A850"))
            .multilineTextAlignment(.center)
            .padding(.horizontal)

        Text(record.lyrics)
            .font(.system(.body, design: .serif))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

        Button(action: { audioManager.speakDJ(record.djScript) }) {
            VStack(spacing: 4) {
                Image(systemName: "radio").font(.title2)
                Text("电台").font(.caption)
            }
            .foregroundStyle(Color(hex: "#E8A850"))
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("推荐歌曲")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let data = record.recommendationsJSON.data(using: .utf8),
               let songs = try? JSONDecoder().decode([SongRecommendation].self, from: data) {
                ForEach(songs) { song in
                    RecommendationRow(recommendation: song)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 32)
    }

    private var shareToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                shareImage = ShareCardRenderer.render(
                    albumTitle: record.albumTitle,
                    lyrics: record.lyrics,
                    mood: record.moodRaw,
                    style: record.styleTagRaw
                )
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Color(hex: "#E8A850"))
            }
        }
    }
}
