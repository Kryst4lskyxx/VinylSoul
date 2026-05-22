import SwiftUI

struct ShareConfigSheet: View {
    @Binding var config: ShareCardConfig
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    Picker("模板", selection: $config.template) {
                        ForEach(ShareCardTemplate.allCases, id: \.self) { tpl in
                            Text(tpl.displayName).tag(tpl)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("内容") {
                    Toggle("显示专辑名", isOn: $config.showAlbumTitle)
                    Toggle("显示歌词", isOn: $config.showLyrics)
                }

                Section("强调色") {
                    Picker("强调色", selection: $config.accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 16, height: 16)
                                Text(colorLabel(color))
                            }
                            .tag(color)
                        }
                    }
                }
            }
            .navigationTitle("分享设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("生成") {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "#E8A850"))
                }
            }
        }
    }

    private func colorLabel(_ color: AccentColor) -> String {
        switch color {
        case .amber: return "琥珀"
        case .white: return "白色"
        case .warm:  return "暖橙"
        }
    }
}
