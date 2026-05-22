import SwiftUI

struct InspirationView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InspirationViewModel()
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title + settings
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

                MoodSlider(mood: $viewModel.mood)
                    .padding(.top, 12)

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
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
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
