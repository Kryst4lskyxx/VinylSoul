import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var appStore
    @State private var apiKeyInput: String = ""
    @State private var showSaved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("请输入 API Key", text: $apiKeyInput)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("DeepSeek API Key")
                } footer: {
                    Text("API Key 将安全存储在系统钥匙串中")
                }

                Section {
                    Button("保存") {
                        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appStore.saveAPIKey(trimmed)
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }

                Section {
                    Link("获取 API Key →",
                         destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("已保存", isPresented: $showSaved) {
                Button("好") { }
            } message: {
                Text("API Key 已安全存储")
            }
            .onAppear {
                apiKeyInput = appStore.apiKey ?? ""
            }
        }
    }
}
