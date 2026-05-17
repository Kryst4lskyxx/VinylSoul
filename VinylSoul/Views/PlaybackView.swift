import SwiftUI

struct PlaybackView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = PlaybackViewModel()
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        Group {
            if let result = appStore.currentResult {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("正在播放")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        SpinningVinyl()
                            .padding(.top, 8)

                        Text(result.albumTitle)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(Color(hex: "#E8A850"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        TypewriterText(text: viewModel.displayedText)
                            .frame(minHeight: 120, maxHeight: 280)
                            .onAppear {
                                viewModel.startTypewriter(text: result.lyrics)
                            }
                            .onDisappear {
                                viewModel.reset()
                            }
                            .onTapGesture {
                                viewModel.skipToEnd()
                            }

                        HStack(spacing: 40) {
                            Button(action: {
                                audioManager.speakDJ(result.djScript)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "radio")
                                        .font(.title2)
                                    Text("电台")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color(hex: "#E8A850"))
                            }

                            Button(action: {
                                audioManager.toggleMute()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: audioManager.isMuted
                                        ? "speaker.slash"
                                        : "speaker.wave.2")
                                        .font(.title2)
                                    Text(audioManager.isMuted ? "静音" : "音乐")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }

                            Button(action: {
                                shareImage = ShareCardRenderer.render(
                                    albumTitle: result.albumTitle,
                                    lyrics: viewModel.displayedText
                                )
                                showShareSheet = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                    Text("分享")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color(hex: "#E8A850"))
                            }
                        }

                        if !result.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("推荐歌曲")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)

                                ForEach(result.recommendations) { song in
                                    RecommendationRow(recommendation: song)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    if let shareImage {
                        ShareSheet(items: [shareImage])
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("还没有灵感，去创作页生成一首吧 🎧")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
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
