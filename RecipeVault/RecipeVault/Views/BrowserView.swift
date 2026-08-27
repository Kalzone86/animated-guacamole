import SwiftUI
@preconcurrency import WebKit

/// Drives a WKWebView and exposes just enough state/control for a SwiftUI
/// address bar and toolbar, plus the ability to snapshot the current page's
/// HTML so the recipe importer can pull structured data out of it.
@Observable
final class WebViewController: NSObject {
    let webView: WKWebView
    var addressText: String = ""
    var pageTitle: String = ""
    var isLoading = false
    var canGoBack = false
    var canGoForward = false

    override init() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        super.init()
        webView.navigationDelegate = self
    }

    func navigate(to text: String) {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let looksLikeURL = trimmed.contains(".") && !trimmed.contains(" ")
        if looksLikeURL {
            if !trimmed.lowercased().hasPrefix("http") {
                trimmed = "https://" + trimmed
            }
        } else {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            trimmed = "https://www.google.com/search?q=\(encoded)"
        }

        guard let url = URL(string: trimmed) else { return }
        webView.load(URLRequest(url: url))
    }

    func extractHTML() async -> String? {
        try? await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        pageTitle = webView.title ?? ""
        if let urlString = webView.url?.absoluteString {
            addressText = urlString
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let controller: WebViewController

    func makeUIView(context: Context) -> WKWebView {
        controller.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// The in-app browser: browse to any recipe site, then tap "Save Recipe" to
/// clip whatever's on screen straight into RecipeVault — the same workflow
/// Paprika's browser tab and Safari extension offer.
struct BrowserView: View {
    @State private var controller = WebViewController()
    @State private var isSavingRecipe = false
    @State private var parsedRecipe: ParsedRecipe?
    @State private var showingEditor = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let startingURL = "https://www.google.com/search?q=recipes"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                addressBar
                Divider()
                WebViewRepresentable(controller: controller)
            }
            .navigationTitle(controller.pageTitle.isEmpty ? "Browse" : controller.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        controller.webView.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!controller.canGoBack)

                    Button {
                        controller.webView.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!controller.canGoForward)

                    Spacer()

                    Button {
                        saveRecipe()
                    } label: {
                        if isSavingRecipe {
                            ProgressView()
                        } else {
                            Label("Save Recipe", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(isSavingRecipe)
                }
            }
            .onAppear {
                if controller.addressText.isEmpty {
                    controller.addressText = startingURL
                    controller.navigate(to: startingURL)
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let parsedRecipe {
                    RecipeEditView(recipe: nil, prefilled: parsedRecipe)
                }
            }
            .alert("Couldn't Save Recipe", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var addressBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Search or enter website address", text: $controller.addressText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .onSubmit {
                    controller.navigate(to: controller.addressText)
                }
            if controller.isLoading {
                ProgressView()
            } else {
                Button {
                    controller.webView.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func saveRecipe() {
        isSavingRecipe = true
        Task {
            defer { isSavingRecipe = false }
            guard let html = await controller.extractHTML() else {
                errorMessage = "Couldn't read this page. Try again once it's fully loaded."
                return
            }
            guard let recipe = await RecipeImporter.parseAndDownloadImage(html: html, sourceURL: controller.webView.url) else {
                errorMessage = "No recipe data was found on this page. Some sites don't publish structured recipe data — you can add it manually instead."
                return
            }
            parsedRecipe = recipe
            showingEditor = true
        }
    }
}
