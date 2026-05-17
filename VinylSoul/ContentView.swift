import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var appStore

    var body: some View {
        TabView(selection: Bindable(appStore).selectedTab) {
            InspirationView()
                .tabItem {
                    Label("创作", systemImage: "pencil.and.outline")
                }
                .tag(0)

            PlaybackView()
                .tabItem {
                    Label("正在播放", systemImage: "record.circle")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("唱片架", systemImage: "square.stack")
                }
                .tag(2)
        }
        .tint(Color(hex: "#E8A850"))
    }
}

// Placeholder stubs — replaced by real views in later tasks
struct InspirationView: View { var body: some View { Text("创作") } }
struct PlaybackView: View { var body: some View { Text("正在播放") } }
struct HistoryView: View { var body: some View { Text("唱片架") } }
