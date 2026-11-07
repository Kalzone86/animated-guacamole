import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Handles creating a brand-new recipe, editing an existing one, or reviewing
/// a recipe that was just parsed from the web before it's saved.
struct RecipeEditView: View {
    let existingRecipe: Recipe?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var ingredients: String
    @State private var directions: String
    @State private var notes: String
    @State private var prepMinutesText: String
    @State private var cookMinutesText: String
    @State private var totalMinutesText: String
    @State private var servings: String
    @State private var tagsText: String
    @State private var sourceName: String
    @State private var sourceURLString: String
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(recipe: Recipe?, prefilled: ParsedRecipe? = nil) {
        self.existingRecipe = recipe
        _name = State(initialValue: recipe?.name ?? prefilled?.name ?? "")
        _description = State(initialValue: recipe?.recipeDescription ?? prefilled?.description ?? "")
        _ingredients = State(initialValue: recipe?.ingredients ?? prefilled?.ingredients ?? "")
        _directions = State(initialValue: recipe?.directions ?? prefilled?.directions ?? "")
        _notes = State(initialValue: recipe?.notes ?? "")
        _prepMinutesText = State(initialValue: Self.minutesText(recipe?.prepTimeMinutes ?? prefilled?.prepTimeMinutes))
        _cookMinutesText = State(initialValue: Self.minutesText(recipe?.cookTimeMinutes ?? prefilled?.cookTimeMinutes))
        _totalMinutesText = State(initialValue: Self.minutesText(recipe?.totalTimeMinutes ?? prefilled?.totalTimeMinutes))
        _servings = State(initialValue: recipe?.servings ?? prefilled?.servings ?? "")
        _tagsText = State(initialValue: recipe?.tags.joined(separator: ", ") ?? "")
        _sourceName = State(initialValue: recipe?.sourceName ?? prefilled?.sourceName ?? "")
        _sourceURLString = State(initialValue: recipe?.sourceURLString ?? prefilled?.sourceURLString ?? "")
        _photoData = State(initialValue: recipe?.photoData ?? prefilled?.photoData)
    }

    private static func minutesText(_ minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "" }
        return String(minutes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }

                Section("Recipe") {
                    TextField("Name", text: $name)
                    TextField("Short Description", text: $description, axis: .vertical)
                    TextField("Tags (comma separated)", text: $tagsText)
                }

                Section("Time & Servings") {
                    HStack {
                        Text("Prep (min)")
                        Spacer()
                        TextField("0", text: $prepMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Cook (min)")
                        Spacer()
                        TextField("0", text: $cookMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Total (min)")
                        Spacer()
                        TextField("0", text: $totalMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Servings", text: $servings)
                }

                Section("Ingredients") {
                    TextEditor(text: $ingredients)
                        .frame(minHeight: 140)
                }

                Section("Directions") {
                    TextEditor(text: $directions)
                        .frame(minHeight: 160)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section("Source") {
                    TextField("Source Name", text: $sourceName)
                    TextField("Source URL", text: $sourceURLString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(existingRecipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let recipe = existingRecipe ?? Recipe()
        recipe.name = name.trimmingCharacters(in: .whitespaces)
        recipe.recipeDescription = description
        recipe.ingredients = ingredients
        recipe.directions = directions
        recipe.notes = notes
        recipe.prepTimeMinutes = Int(prepMinutesText) ?? 0
        recipe.cookTimeMinutes = Int(cookMinutesText) ?? 0
        recipe.totalTimeMinutes = Int(totalMinutesText) ?? 0
        recipe.servings = servings
        recipe.tags = tags
        recipe.sourceName = sourceName
        recipe.sourceURLString = sourceURLString
        recipe.photoData = photoData
        recipe.updatedAt = .now

        if existingRecipe == nil {
            modelContext.insert(recipe)
        }

        dismiss()
    }
}
