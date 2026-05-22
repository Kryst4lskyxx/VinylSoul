import SwiftUI
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionHandler.shared.pendingAction = shortcutItem.type
        }
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionHandler.shared.pendingAction = shortcutItem.type
        completionHandler(true)
    }
}

@MainActor @Observable
final class QuickActionHandler {
    static let shared = QuickActionHandler()
    var pendingAction: String?
}

@main
struct VinylSoulApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
    @Environment(AppStore.self) private var appStore
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
                    handlePendingAction()
                case .background:
                    notificationManager.scheduleDailyInspiration()
                default:
                    break
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
    }

    private func handlePendingAction() {
        guard let action = QuickActionHandler.shared.pendingAction else { return }
        QuickActionHandler.shared.pendingAction = nil
        switch action {
        case "generateInspiration": appStore.selectedTab = 0
        case "viewFavorites", "viewHistory": appStore.selectedTab = 2
        default: break
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        switch host {
        case "generate": appStore.selectedTab = 0
        case "latest", "history":  appStore.selectedTab = 2
        case "stats":
            appStore.selectedTab = 2
            appStore.showStats = true
        default: break
        }
    }
}
