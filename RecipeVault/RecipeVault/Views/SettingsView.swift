import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]

    var body: some View {
        @Bindable var appearanceManager = appearanceManager

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceManager.appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    LabeledContent("Recipes Saved", value: "\(recipes.count)")
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text("Recipes sync automatically through your iCloud account to every device signed in with the same Apple ID — no extra setup needed once iCloud Drive is turned on for this app in Settings. Make sure you're signed in to the same iCloud account on your Mac and iPhone to see the same recipes on both.")
                }

                Section {
                    Link(destination: URL(string: "https://support.apple.com/en-us/HT204025")!) {
                        Label("About iCloud Sync", systemImage: "icloud")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
