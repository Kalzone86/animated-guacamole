import SwiftUI
import UIKit

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name.isEmpty ? "Untitled Recipe" : recipe.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if recipe.totalTimeMinutes > 0 {
                        Label(ISO8601DurationParser.label(fromMinutes: recipe.totalTimeMinutes), systemImage: "clock")
                    }
                    if !recipe.servings.isEmpty {
                        Label(recipe.servings, systemImage: "person.2")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if recipe.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let photoData = recipe.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(Color.accentColor)
                }
        }
    }
}
