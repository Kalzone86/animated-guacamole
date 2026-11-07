import Foundation

/// The result of successfully parsing a recipe page, before it has been
/// turned into a persisted `Recipe`.
struct ParsedRecipe {
    var name: String = ""
    var description: String = ""
    var ingredients: String = ""
    var directions: String = ""
    var prepTimeMinutes: Int = 0
    var cookTimeMinutes: Int = 0
    var totalTimeMinutes: Int = 0
    var servings: String = ""
    var sourceName: String = ""
    var sourceURLString: String = ""
    var imageURLString: String?
    var photoData: Data?
}

enum RecipeImportError: LocalizedError {
    case invalidURL
    case network(Error)
    case noRecipeFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That doesn't look like a valid web address."
        case .network(let error):
            return "Couldn't load the page: \(error.localizedDescription)"
        case .noRecipeFound:
            return "No recipe data was found on this page. Some sites don't publish structured recipe data — you can still add the recipe manually."
        }
    }
}

enum RecipeImporter {
    /// Fetches a URL and extracts a recipe from its embedded JSON-LD.
    static func importFromURL(_ urlString: String) async throws -> ParsedRecipe {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.lowercased().hasPrefix("http") {
            trimmed = "https://" + trimmed
        }
        guard let url = URL(string: trimmed) else {
            throw RecipeImportError.invalidURL
        }

        let html: String
        do {
            var request = URLRequest(url: url)
            request.setValue(
                "Mozilla/5.0 (compatible; RecipeVault/1.0; +https://example.com)",
                forHTTPHeaderField: "User-Agent"
            )
            let (data, _) = try await URLSession.shared.data(for: request)
            html = String(data: data, encoding: .utf8) ?? ""
        } catch {
            throw RecipeImportError.network(error)
        }

        guard let recipe = await parseAndDownloadImage(html: html, sourceURL: url) else {
            throw RecipeImportError.noRecipeFound
        }

        return recipe
    }

    /// Parses HTML for recipe data and, if an image was found, downloads it
    /// so the recipe can be saved with a photo already attached.
    static func parseAndDownloadImage(html: String, sourceURL: URL?) async -> ParsedRecipe? {
        guard var recipe = parse(html: html, sourceURL: sourceURL) else { return nil }
        if let imageURLString = recipe.imageURLString, let imageURL = URL(string: imageURLString) {
            recipe.photoData = try? await downloadImage(from: imageURL)
        }
        return recipe
    }

    /// Parses recipe data directly out of an HTML string. Used both for
    /// direct URL imports and for the in-app browser's "Save Recipe" action,
    /// which hands over the currently rendered page's HTML.
    static func parse(html: String, sourceURL: URL?) -> ParsedRecipe? {
        guard let schema = firstRecipeSchema(in: html) else { return nil }

        var parsed = ParsedRecipe()
        parsed.name = decodeHTMLEntities(schema.name ?? "")
        parsed.description = decodeHTMLEntities(schema.description ?? "")
        parsed.ingredients = (schema.recipeIngredient ?? [])
            .map { decodeHTMLEntities($0) }
            .joined(separator: "\n")
        parsed.directions = (schema.recipeInstructions?.steps ?? [])
            .map { decodeHTMLEntities($0) }
            .joined(separator: "\n")
        parsed.prepTimeMinutes = ISO8601DurationParser.minutes(from: schema.prepTime)
        parsed.cookTimeMinutes = ISO8601DurationParser.minutes(from: schema.cookTime)
        parsed.totalTimeMinutes = ISO8601DurationParser.minutes(from: schema.totalTime)
        parsed.servings = schema.recipeYield?.value ?? ""
        parsed.sourceName = schema.author?.name ?? sourceURL?.host ?? ""
        parsed.sourceURLString = sourceURL?.absoluteString ?? ""
        parsed.imageURLString = schema.image?.values.first

        guard !parsed.name.isEmpty || !parsed.ingredients.isEmpty else { return nil }
        return parsed
    }

    private static func firstRecipeSchema(in html: String) -> SchemaRecipe? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return nil
        }

        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)

        for match in matches {
            guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[range])
            guard let jsonData = jsonString.data(using: .utf8) else { continue }
            if let recipe = SchemaGraph.extractRecipe(from: jsonData) {
                return recipe
            }
        }
        return nil
    }

    private static func downloadImage(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        guard string.contains("&") else { return string }
        let replacements: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'",
            "&nbsp;": " ", "&rsquo;": "\u{2019}", "&lsquo;": "\u{2018}",
            "&rdquo;": "\u{201D}", "&ldquo;": "\u{201C}", "&frac12;": "\u{00BD}",
            "&frac14;": "\u{00BC}", "&frac34;": "\u{00BE}", "&deg;": "\u{00B0}"
        ]
        var result = string
        for (entity, replacement) in replacements {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}
