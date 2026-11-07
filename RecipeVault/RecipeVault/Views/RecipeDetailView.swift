import SwiftUI
import SwiftData
import UIKit

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                metaRow

                if !recipe.tags.isEmpty {
                    tagChips
                }

                if !recipe.recipeDescription.isEmpty {
                    Text(recipe.recipeDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if !recipe.ingredients.isEmpty {
                    sectionCard(title: "Ingredients") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredientLines, id: \.self) { line in
                                Label(line, systemImage: "circle")
                                    .labelStyle(BulletLabelStyle())
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                if !recipe.directions.isEmpty {
                    sectionCard(title: "Directions") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recipe.directionSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.accentColor))
                                    Text(step)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }

                if !recipe.notes.isEmpty {
                    sectionCard(title: "Notes") {
                        Text(recipe.notes).font(.subheadline)
                    }
                }

                if let url = recipe.sourceURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label(recipe.sourceName.isEmpty ? url.host ?? "Source" : "From \(recipe.sourceName)", systemImage: "link")
                    }
                    .font(.footnote)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name.isEmpty ? "Recipe" : recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipe.isFavorite.toggle()
                    recipe.updatedAt = .now
                } label: {
                    Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RecipeEditView(recipe: recipe)
        }
        .confirmationDialog("Delete this recipe?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(recipe)
                dismiss()
            }
        }
    }

    private var header: some View {
        Group {
            if let photoData = recipe.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 16) {
            if recipe.prepTimeMinutes > 0 {
                metaItem(label: "Prep", value: ISO8601DurationParser.label(fromMinutes: recipe.prepTimeMinutes))
            }
            if recipe.cookTimeMinutes > 0 {
                metaItem(label: "Cook", value: ISO8601DurationParser.label(fromMinutes: recipe.cookTimeMinutes))
            }
            if recipe.totalTimeMinutes > 0 {
                metaItem(label: "Total", value: ISO8601DurationParser.label(fromMinutes: recipe.totalTimeMinutes))
            }
            if !recipe.servings.isEmpty {
                metaItem(label: "Serves", value: recipe.servings)
            }
        }
    }

    private func metaItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                }
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().frame(width: 5, height: 5).padding(.top, 7).opacity(0.5)
            configuration.title
        }
    }
}
