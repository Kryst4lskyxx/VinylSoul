import SwiftUI
import SwiftData

@main
struct VinylSoulApp: App {
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appStore)
                .environment(audioManager)
        }
        .modelContainer(for: InspirationRecord.self)
    }
}

struct AppRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    private let notificationManager = NotificationManager()

    var body: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .onAppear {
                notificationManager.requestAuthorization()
                notificationManager.scheduleDailyInspiration()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    notificationManager.markAppOpened()
                case .background:
                    notificationManager.scheduleDailyInspiration()
                default:
                    break
                }
            }
    }
}
