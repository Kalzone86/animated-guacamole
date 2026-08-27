import SwiftUI

/// Paste-a-link importer: the quick path when you already have a recipe URL
/// (e.g. copied from Safari, Messages, or another app's share sheet).
struct ImportRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedRecipe: ParsedRecipe?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/recipe", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } header: {
                    Text("Recipe URL")
                } footer: {
                    Text("Works with most recipe blogs and cooking sites that publish structured recipe data.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Import from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        importRecipe()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Import")
                        }
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showingEditor, onDismiss: { dismiss() }) {
                if let parsedRecipe {
                    RecipeEditView(recipe: nil, prefilled: parsedRecipe)
                }
            }
        }
    }

    private func importRecipe() {
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                parsedRecipe = try await RecipeImporter.importFromURL(urlText)
                showingEditor = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
