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
                .toolbarBackground(.hidden, for: .tabBar)

            PlaybackView()
                .tabItem {
                    Label("正在播放", systemImage: "record.circle")
                }
                .tag(1)
                .toolbarBackground(.hidden, for: .tabBar)

            HistoryView()
                .tabItem {
                    Label("唱片架", systemImage: "square.stack")
                }
                .tag(2)
                .toolbarBackground(.hidden, for: .tabBar)
        }
        .tint(Color(hex: "#E8A850"))
        .background(Color(hex: "#0d0d0d").ignoresSafeArea())
    }
}
