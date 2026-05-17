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
