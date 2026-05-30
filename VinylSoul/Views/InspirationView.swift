import SwiftUI

struct InspirationView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel = InspirationViewModel()
    @State private var showSettings = false

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 0) {
                leftPanel
                    .frame(width: 320)
                    .padding(.leading, 40)
                    .padding(.top, 60)

                ScrollView {
                    formContent
                        .frame(maxWidth: 600)
                        .padding(.trailing, 40)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
                .scrollContentBackground(.hidden)
            }
        } else {
            ScrollView {
                formContent
                    .frame(maxWidth: 600)
                    .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
        }
    }

    private var leftPanel: some View {
        VStack(spacing: 24) {
            Spacer()

            // Decorative vinyl
            ZStack {
                Circle()
                    .stroke(Color(hex: "#E8A850").opacity(0.15), lineWidth: 2)
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(Color(hex: "#0d0d0d"))
                    .frame(width: 60, height: 60)

                Circle()
                    .stroke(Color(hex: "#E8A850").opacity(0.3), lineWidth: 1)
                    .frame(width: 60, height: 60)

                Image(systemName: "record.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "#E8A850"))
            }

            VStack(spacing: 4) {
                Text("VinylSoul")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color(hex: "#E8A850"))
                Text("R&B 灵感创作")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("选择心情，设定风格，\n让 AI 为你创作独特的 R&B 歌词。")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    private var formContent: some View {
        VStack(spacing: 24) {
            // Title + settings (compact only)
            if horizontalSizeClass != .regular {
                HStack {
                    Text("VinylSoul")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color(hex: "#E8A850"))
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "#E8A850"))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            MoodSlider(mood: $viewModel.mood)
                .padding(.top, horizontalSizeClass == .regular ? 0 : 12)

            // Keywords
            VStack(alignment: .leading, spacing: 8) {
                Text("关键词")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField("输入关键词，如：雨夜、末班车...",
                          text: $viewModel.keywords)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // Style tags
            VStack(alignment: .leading, spacing: 8) {
                Text("风格")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(StyleTag.allCases, id: \.self) { style in
                        StyleTagChip(
                            style: style,
                            isSelected: viewModel.selectedStyle == style
                        ) {
                            viewModel.selectedStyle = style
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Generate button
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                viewModel.generate(appStore: appStore, modelContext: modelContext)
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    }
                    Text(viewModel.isLoading ? "正在创作中..." : "生成灵感")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canGenerate
                    ? Color(hex: "#E8A850")
                    : Color(.systemGray4))
                .foregroundStyle(viewModel.canGenerate ? .black : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canGenerate)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("提示", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
