import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.updatedAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedTag: String?
    @State private var showingAddMenu = false
    @State private var showingManualEditor = false
    @State private var showingURLImport = false
    @State private var showingBrowser = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeRowView(recipe: recipe)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(recipe)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavorite(recipe)
                                } label: {
                                    Label("Favorite", systemImage: recipe.isFavorite ? "star.slash" : "star")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes or tags")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingManualEditor = true
                        } label: {
                            Label("Add Recipe Manually", systemImage: "square.and.pencil")
                        }
                        Button {
                            showingURLImport = true
                        } label: {
                            Label("Import from URL", systemImage: "link")
                        }
                        Button {
                            showingBrowser = true
                        } label: {
                            Label("Browse the Web", systemImage: "safari")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $showFavoritesOnly) {
                            Label("Favorites Only", systemImage: "star")
                        }
                        if !allTags.isEmpty {
                            Divider()
                            Button("All Tags") { selectedTag = nil }
                            ForEach(allTags, id: \.self) { tag in
                                Button {
                                    selectedTag = tag
                                } label: {
                                    if selectedTag == tag {
                                        Label(tag, systemImage: "checkmark")
                                    } else {
                                        Text(tag)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingManualEditor) {
                RecipeEditView(recipe: nil)
            }
            .sheet(isPresented: $showingURLImport) {
                ImportRecipeView()
            }
            .sheet(isPresented: $showingBrowser) {
                BrowserView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var allTags: [String] {
        Array(Set(recipes.flatMap(\.tags))).sorted()
    }

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            if showFavoritesOnly && !recipe.isFavorite { return false }
            if let selectedTag, !recipe.tags.contains(selectedTag) { return false }
            if searchText.isEmpty { return true }
            let haystack = ([recipe.name, recipe.ingredients] + recipe.tags).joined(separator: " ").lowercased()
            return haystack.contains(searchText.lowercased())
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Recipes Yet", systemImage: "fork.knife.circle")
        } description: {
            Text("Add a recipe manually, paste a link, or browse the web and save recipes as you find them.")
        } actions: {
            Button("Browse the Web") { showingBrowser = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func delete(_ recipe: Recipe) {
        modelContext.delete(recipe)
    }

    private func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        recipe.updatedAt = .now
    }
}
