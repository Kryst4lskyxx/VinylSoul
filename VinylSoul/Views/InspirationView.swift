import SwiftUI

struct InspirationView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InspirationViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                MoodSlider(mood: $viewModel.mood)

                VStack(alignment: .leading, spacing: 8) {
                    Text("关键词")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("输入关键词，如：雨夜、末班车...",
                              text: $viewModel.keywords)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("风格")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
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

                Spacer()
            }
            .navigationTitle("VinylSoul")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "#E8A850"))
                    }
                }
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
}
