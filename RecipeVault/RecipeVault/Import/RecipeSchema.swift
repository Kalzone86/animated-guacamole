import Foundation

/// Decodes schema.org/Recipe JSON-LD, the structured data format nearly every
/// modern recipe site embeds so Google can show rich results. Because sites
/// are inconsistent about whether a field is a string, an array, or an object,
/// most fields use a permissive decoding helper (`FlexibleString`/`FlexibleStringArray`)
/// instead of a strict type.
struct SchemaRecipe: Decodable {
    let type: FlexibleStringArray?
    let name: String?
    let description: String?
    let image: FlexibleStringArray?
    let recipeIngredient: [String]?
    let recipeInstructions: FlexibleInstructions?
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let recipeYield: FlexibleString?
    let author: FlexibleAuthor?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name, description, image
        case recipeIngredient, recipeInstructions
        case prepTime, cookTime, totalTime, recipeYield, author
    }

    var isRecipe: Bool {
        type?.values.contains { $0.caseInsensitiveCompare("Recipe") == .orderedSame } ?? false
    }
}

/// Top-level JSON-LD can be a single object, an array of objects, or a
/// `{"@graph": [...]}` wrapper. This tries all three shapes.
struct SchemaGraph: Decodable {
    let graph: [SchemaRecipe]?

    enum CodingKeys: String, CodingKey {
        case graph = "@graph"
    }

    static func extractRecipe(from jsonData: Data) -> SchemaRecipe? {
        let decoder = JSONDecoder()

        if let single = try? decoder.decode(SchemaRecipe.self, from: jsonData), single.isRecipe {
            return single
        }
        if let array = try? decoder.decode([SchemaRecipe].self, from: jsonData) {
            return array.first { $0.isRecipe }
        }
        if let graph = try? decoder.decode(SchemaGraph.self, from: jsonData) {
            return graph.graph?.first { $0.isRecipe }
        }
        return nil
    }
}

/// A value that may arrive as a plain string or as a number/object with a
/// "@value"-style representation. Falls back to describing whatever it finds.
struct FlexibleString: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else if let dict = try? container.decode([String: FlexibleJSONValue].self) {
            value = dict["name"]?.stringValue ?? dict["value"]?.stringValue ?? ""
        } else {
            value = ""
        }
    }
}

/// A value that may be a single string, an array of strings, or an array of
/// objects (e.g. ImageObject) each carrying a "url" field.
struct FlexibleStringArray: Decodable {
    let values: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            values = [string]
        } else if let array = try? container.decode([String].self) {
            values = array
        } else if let dict = try? container.decode([String: FlexibleJSONValue].self) {
            if let url = dict["url"]?.stringValue {
                values = [url]
            } else {
                values = []
            }
        } else if let arrayOfDicts = try? container.decode([[String: FlexibleJSONValue]].self) {
            values = arrayOfDicts.compactMap { $0["url"]?.stringValue }
        } else {
            values = []
        }
    }
}

struct FlexibleAuthor: Decodable {
    let name: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            name = string
        } else if let dict = try? container.decode([String: FlexibleJSONValue].self) {
            name = dict["name"]?.stringValue
        } else {
            name = nil
        }
    }
}

/// `recipeInstructions` can be: a single string of steps, an array of
/// strings, an array of HowToStep objects, or nested HowToSection objects
/// each containing their own itemListElement of HowToSteps.
struct FlexibleInstructions: Decodable {
    let steps: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            steps = string
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return
        }

        if let array = try? container.decode([String].self) {
            steps = array
            return
        }

        if let objects = try? container.decode([HowToNode].self) {
            steps = objects.flatMap { $0.flattenedText }
            return
        }

        steps = []
    }
}

/// Represents either a HowToStep ("text") or a HowToSection
/// ("itemListElement": [HowToStep, ...]).
struct HowToNode: Decodable {
    let type: String?
    let text: String?
    let name: String?
    let itemListElement: [HowToNode]?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case text, name, itemListElement
    }

    var flattenedText: [String] {
        if let itemListElement, !itemListElement.isEmpty {
            return itemListElement.flatMap { $0.flattenedText }
        }
        if let text, !text.isEmpty {
            return [text]
        }
        if let name, !name.isEmpty {
            return [name]
        }
        return []
    }
}

/// Catch-all JSON value used when decoding untyped dictionaries.
enum FlexibleJSONValue: Decodable {
    case string(String)
    case number(Double)
    case object([String: FlexibleJSONValue])
    case array([FlexibleJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let object = try? container.decode([String: FlexibleJSONValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([FlexibleJSONValue].self) {
            self = .array(array)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .number(let value): return String(value)
        default: return nil
        }
    }
}
