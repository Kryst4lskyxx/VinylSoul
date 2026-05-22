import SwiftUI
import SwiftData

@main
struct VinylSoulApp: App {
    @State private var appStore = AppStore()
    @State private var audioManager = AudioManager()
    @State private var musicService = MusicService()

    private let appGroupID = "group.com.vinylsoul.app"

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appStore)
                .environment(audioManager)
                .environment(musicService)
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            fatalError("App Group container URL not found. Check provisioning profile.")
        }
        let storeURL = containerURL.appendingPathComponent("VinylSoul.sqlite")
        let configuration = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: InspirationRecord.self, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
