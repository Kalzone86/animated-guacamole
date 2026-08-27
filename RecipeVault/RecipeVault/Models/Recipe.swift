import Foundation
import SwiftData

/// Core recipe entity. All properties carry default values and every
/// relationship-free attribute is either optional or defaulted, which is
/// required for SwiftData's automatic CloudKit sync (NSPersistentCloudKitContainer
/// rules apply: no unique constraints, no non-optional attributes without defaults).
@Model
final class Recipe {
    var id: UUID = UUID()
    var name: String = ""
    var recipeDescription: String = ""
    var ingredients: String = ""
    var directions: String = ""
    var notes: String = ""

    var prepTimeMinutes: Int = 0
    var cookTimeMinutes: Int = 0
    var totalTimeMinutes: Int = 0
    var servings: String = ""
    var difficulty: String = ""
    var rating: Int = 0

    var sourceName: String = ""
    var sourceURLString: String = ""

    var tags: [String] = []
    var isFavorite: Bool = false

    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    // Large binary payloads are pushed to external storage so the main
    // record stays small and CloudKit sync stays fast.
    @Attribute(.externalStorage) var photoData: Data?

    init(
        id: UUID = UUID(),
        name: String = "",
        recipeDescription: String = "",
        ingredients: String = "",
        directions: String = "",
        notes: String = "",
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        totalTimeMinutes: Int = 0,
        servings: String = "",
        difficulty: String = "",
        rating: Int = 0,
        sourceName: String = "",
        sourceURLString: String = "",
        tags: [String] = [],
        isFavorite: Bool = false,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.ingredients = ingredients
        self.directions = directions
        self.notes = notes
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.totalTimeMinutes = totalTimeMinutes
        self.servings = servings
        self.difficulty = difficulty
        self.rating = rating
        self.sourceName = sourceName
        self.sourceURLString = sourceURLString
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = .now
        self.updatedAt = .now
        self.photoData = photoData
    }

    var ingredientLines: [String] {
        ingredients
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var directionSteps: [String] {
        directions
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var sourceURL: URL? {
        URL(string: sourceURLString)
    }
}
