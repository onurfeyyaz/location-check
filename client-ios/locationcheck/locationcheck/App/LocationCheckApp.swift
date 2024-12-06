import SwiftUI
import SwiftData

@main
struct LocationCheckApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([StoredLocation.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: LocationViewModel())
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