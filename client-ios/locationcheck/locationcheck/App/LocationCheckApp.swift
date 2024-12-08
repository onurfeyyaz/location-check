import SwiftUI
import SwiftData

@main
struct LocationCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([DeviceDetails.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                LocationHistoryView()
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        Task {
            await AppLaunchManager.handleAppLaunch()
        }
        print("handle")
        return true
    }
}
