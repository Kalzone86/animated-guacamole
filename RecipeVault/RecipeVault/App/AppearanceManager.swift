import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Persists the user's chosen appearance and exposes it as a ColorScheme
/// override for the root view. Defaults to following the system setting.
@Observable
final class AppearanceManager {
    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "appAppearance"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: stored) ?? .system
    }
}
