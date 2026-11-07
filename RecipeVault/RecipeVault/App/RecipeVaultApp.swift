import SwiftUI
import SwiftData

@main
struct RecipeVaultApp: App {
    @State private var appearanceManager = AppearanceManager()

    /// SwiftData's built-in CloudKit sync. Every device signed into the same
    /// iCloud account and running this app shares this private database
    /// automatically — no server, accounts, or extra code required. This is
    /// what keeps a Mac app and this iPhone app in sync once a Mac target
    /// is added to the project (see README).
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Recipe.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .environment(appearanceManager)
                .preferredColorScheme(appearanceManager.appearance.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
