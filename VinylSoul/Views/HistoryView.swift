import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("还没有灵感唱片，去创作一张吧 🎵")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.records) { record in
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
                                viewModel.delete(viewModel.records[index], modelContext: modelContext)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("唱片架")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetch(modelContext: modelContext)
            }
        }
    }
}

struct PastPlaybackView: View {
    let record: InspirationRecord
    @Environment(AudioManager.self) private var audioManager
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SpinningVinyl()
                    .padding(.top, 32)

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

                Button(action: {
                    audioManager.speakDJ(record.djScript)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "radio")
                            .font(.title2)
                        Text("电台")
                            .font(.caption)
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
        }
        .navigationTitle(record.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
        .onAppear {
            audioManager.playLoFi()
        }
        .onDisappear {
            audioManager.stopLoFi()
        }
    }
}
