import SwiftUI
import SwiftData

@main
struct dreamAppApp: App {
    @AppStorage("currentUserId") private var currentUserId: String = ""

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            SleepSchedule.self,
            AudioFile.self,
            SleepSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if currentUserId.isEmpty {
                LoginView()
            } else {
                HomeTabView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
