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

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appStore)
                .environment(audioManager)
                .environment(musicService)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    private let sharedModelContainer: ModelContainer = {
        if let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.vinylsoul.app") {
            let storeURL = containerURL.appendingPathComponent("VinylSoul.sqlite")
            let configuration = ModelConfiguration(url: storeURL)
            if let container = try? ModelContainer(for: InspirationRecord.self, configurations: configuration) {
                return container
            }
        }
        guard let container = try? ModelContainer(for: InspirationRecord.self) else {
            fatalError("Failed to create ModelContainer")
        }
        return container
    }()
}

struct AppRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppStore.self) private var appStore
    private let notificationManager = NotificationManager()

    var body: some View {
        ContentView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0d0d0d").ignoresSafeArea())
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
