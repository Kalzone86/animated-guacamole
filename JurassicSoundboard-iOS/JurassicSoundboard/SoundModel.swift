import SwiftUI

enum SoundCategory: String, CaseIterable {
    case dino     = "🦕  Dinosaurs"
    case rexRoar  = "🦖  Rex Roars"
    case rexGrowl = "😤  Rex Growls"
    case rexBonus = "🔥  Rex Specials"
    case quote    = "💬  Famous Quotes"
    case music    = "🎵  Music"

    var gradientColors: [Color] {
        switch self {
        case .dino:     return [Color(hex: "1b3d1b"), Color(hex: "0f270f")]
        case .rexRoar:  return [Color(hex: "3d1b1b"), Color(hex: "270f0f")]
        case .rexGrowl: return [Color(hex: "2d1b3d"), Color(hex: "1a0f27")]
        case .rexBonus: return [Color(hex: "3d2a1b"), Color(hex: "27180f")]
        case .quote:    return [Color(hex: "2a2000"), Color(hex: "1a1400")]
        case .music:    return [Color(hex: "1a1a2e"), Color(hex: "0f0f1f")]
        }
    }

    var glowColor: Color {
        switch self {
        case .dino:     return Color(hex: "2e7d2e")
        case .rexRoar:  return Color(hex: "cc3333")
        case .rexGrowl: return Color(hex: "7744cc")
        case .rexBonus: return Color(hex: "cc7733")
        case .quote:    return Color(hex: "c8a84b")
        case .music:    return Color(hex: "5555cc")
        }
    }
}

struct Sound: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let category: SoundCategory
    let filename: String
}

let allSounds: [Sound] = [
    // ── Other dinosaurs ────────────────────────────────────────────────────
    Sound(id: "trex-roar",      label: "T-Rex Roar",         emoji: "🦖", category: .dino, filename: "trex-roar"),
    Sound(id: "trex-scream",    label: "T-Rex Scream",        emoji: "🦖", category: .dino, filename: "trex-scream"),
    Sound(id: "trex-roar-alt",  label: "T-Rex Alt Roar",      emoji: "🦖", category: .dino, filename: "trex-roar-alt"),
    Sound(id: "trex-roar-3",    label: "T-Rex Roar 3",        emoji: "🦖", category: .dino, filename: "trex-roar-3"),
    Sound(id: "raptor-screech", label: "Raptor Screech",      emoji: "🦎", category: .dino, filename: "raptor-screech"),
    Sound(id: "raptor-bark",    label: "Raptor Bark",         emoji: "🦎", category: .dino, filename: "raptor-bark"),
    Sound(id: "raptor-call",    label: "Raptor Call",         emoji: "🦎", category: .dino, filename: "raptor-call"),
    Sound(id: "raptor-attack",  label: "Raptor Attack",       emoji: "🦎", category: .dino, filename: "raptor-attack"),
    Sound(id: "brachiosaurus",  label: "Brachiosaurus",       emoji: "🦕", category: .dino, filename: "brachiosaurus"),
    Sound(id: "diloph-spit",    label: "Dilophosaurus Spit",  emoji: "🐊", category: .dino, filename: "dilophosaurus-spit"),
    Sound(id: "diloph-call",    label: "Dilophosaurus Call",  emoji: "🐊", category: .dino, filename: "dilophosaurus-call"),
    Sound(id: "dino-roar",      label: "Dino Roar",           emoji: "🦕", category: .dino, filename: "dino-roar"),
    Sound(id: "baryonyx",       label: "Baryonyx Roar",       emoji: "🐉", category: .dino, filename: "baryonyx-roar"),
    Sound(id: "godzilla",       label: "Godzilla Roar",       emoji: "👾", category: .dino, filename: "godzilla-roar"),

    // ── Rex Roars ─────────────────────────────────────────────────────────
    Sound(id: "rex-here-she-comes",   label: "HERE SHE COMES!",  emoji: "🦖", category: .rexRoar, filename: "trex-here-she-comes"),
    Sound(id: "rex-gate-crasher",     label: "Gate Crasher",      emoji: "🦖", category: .rexRoar, filename: "trex-gate-crasher"),
    Sound(id: "rex-the-breakout",     label: "The Breakout",      emoji: "🦖", category: .rexRoar, filename: "trex-the-breakout"),
    Sound(id: "rex-warning-shot",     label: "Warning Shot",      emoji: "🦖", category: .rexRoar, filename: "trex-warning-shot"),
    Sound(id: "rex-paddock-escape",   label: "Paddock Escape",    emoji: "🦖", category: .rexRoar, filename: "trex-paddock-escape"),
    Sound(id: "rex-short-and-loud",   label: "Short & LOUD",      emoji: "🦖", category: .rexRoar, filename: "trex-short-and-loud"),
    Sound(id: "rex-quick-snap",       label: "Quick Snap",        emoji: "🦖", category: .rexRoar, filename: "trex-quick-snap"),
    Sound(id: "rex-dont-move",        label: "Don't Move",        emoji: "🦖", category: .rexRoar, filename: "trex-dont-move"),
    Sound(id: "rex-she-found-you",    label: "She Found You",     emoji: "🦖", category: .rexRoar, filename: "trex-she-found-you"),
    Sound(id: "rex-sniff-and-roar",   label: "Sniff & Roar",      emoji: "🦖", category: .rexRoar, filename: "trex-sniff-and-roar"),
    Sound(id: "rex-jungle-thunder",   label: "Jungle Thunder",    emoji: "🦖", category: .rexRoar, filename: "trex-jungle-thunder"),
    Sound(id: "rex-big-entrance",     label: "Big Entrance",      emoji: "🦖", category: .rexRoar, filename: "trex-big-entrance"),
    Sound(id: "rex-feeding-frenzy",   label: "Feeding Frenzy",    emoji: "🦖", category: .rexRoar, filename: "trex-feeding-frenzy"),
    Sound(id: "rex-night-patrol",     label: "Night Patrol",      emoji: "🦖", category: .rexRoar, filename: "trex-night-patrol"),
    Sound(id: "rex-i-smell-you",      label: "I Smell You",       emoji: "🦖", category: .rexRoar, filename: "trex-i-smell-you"),
    Sound(id: "rex-roooaaarrr",       label: "ROOOAAARRR!",       emoji: "🦖", category: .rexRoar, filename: "trex-roooaaarrr"),
    Sound(id: "rex-stomp-walk",       label: "Stomp Walk",        emoji: "🦖", category: .rexRoar, filename: "trex-stomp-walk"),
    Sound(id: "rex-headlight-stare",  label: "Headlight Stare",   emoji: "🦖", category: .rexRoar, filename: "trex-headlight-stare"),
    Sound(id: "rex-river-chase",      label: "River Chase",       emoji: "🦖", category: .rexRoar, filename: "trex-river-chase"),
    Sound(id: "rex-victory-lap",      label: "Victory Lap",       emoji: "🦖", category: .rexRoar, filename: "trex-victory-lap"),
    Sound(id: "rex-king-of-the-park", label: "King of the Park",  emoji: "🦖", category: .rexRoar, filename: "trex-king-of-the-park"),
    Sound(id: "rex-tour-bus-terror",  label: "Tour Bus Terror",   emoji: "🦖", category: .rexRoar, filename: "trex-tour-bus-terror"),
    Sound(id: "rex-sunrise-roar",     label: "Sunrise Roar",      emoji: "🦖", category: .rexRoar, filename: "trex-sunrise-roar"),
    Sound(id: "rex-last-roar",        label: "Last Roar",         emoji: "🦖", category: .rexRoar, filename: "trex-last-roar"),
    Sound(id: "rex-saves-the-day",    label: "Saves the Day",     emoji: "🦖", category: .rexRoar, filename: "trex-saves-the-day"),

    // ── Rex Growls ────────────────────────────────────────────────────────
    Sound(id: "rex-low-rumble",       label: "Low Rumble",        emoji: "😤", category: .rexGrowl, filename: "trex-low-rumble"),
    Sound(id: "rex-deep-snarl",       label: "Deep Snarl",        emoji: "😤", category: .rexGrowl, filename: "trex-deep-snarl"),
    Sound(id: "rex-getting-closer",   label: "Getting Closer",    emoji: "😤", category: .rexGrowl, filename: "trex-getting-closer"),
    Sound(id: "rex-behind-the-trees", label: "Behind the Trees",  emoji: "😤", category: .rexGrowl, filename: "trex-behind-the-trees"),
    Sound(id: "rex-sniffing-around",  label: "Sniffing Around",   emoji: "😤", category: .rexGrowl, filename: "trex-sniffing-around"),
    Sound(id: "rex-the-stalk",        label: "The Stalk",         emoji: "😤", category: .rexGrowl, filename: "trex-the-stalk"),
    Sound(id: "rex-takes-a-hit",      label: "Takes a Hit",       emoji: "💥", category: .rexGrowl, filename: "trex-takes-a-hit"),
    Sound(id: "rex-feels-the-sting",  label: "Feels the Sting",   emoji: "💥", category: .rexGrowl, filename: "trex-feels-the-sting"),

    // ── Rex Specials ──────────────────────────────────────────────────────
    Sound(id: "rex-full-rampage",     label: "Full Rampage",      emoji: "🔥", category: .rexBonus, filename: "trex-full-rampage"),
    Sound(id: "rex-loudest-roar",     label: "LOUDEST ROAR",      emoji: "📢", category: .rexBonus, filename: "trex-loudest-roar"),
    Sound(id: "rex-cgi-classic",      label: "CGI Classic",       emoji: "🎬", category: .rexBonus, filename: "trex-cgi-classic"),

    // ── Famous Quotes ─────────────────────────────────────────────────────
    Sound(id: "welcome",         label: "Welcome to JP",        emoji: "🌿", category: .quote, filename: "welcome-to-jurassic-park"),
    Sound(id: "life-finds-way",  label: "Life Finds a Way",     emoji: "🧬", category: .quote, filename: "life-finds-a-way"),
    Sound(id: "hold-butts",      label: "Hold Onto Your Butts", emoji: "🚬", category: .quote, filename: "hold-onto-your-butts"),
    Sound(id: "spared-expense",  label: "Spared No Expense",    emoji: "💰", category: .quote, filename: "spared-no-expense"),
    Sound(id: "clever-girl",     label: "Clever Girl",          emoji: "🎓", category: .quote, filename: "clever-girl"),
    Sound(id: "hammond-biz",     label: "Hammond: Back in Biz", emoji: "🧓", category: .quote, filename: "hammond-back-in-business"),
    Sound(id: "nedry-ahahah",    label: "Ah Ah Ah!",            emoji: "🖥️", category: .quote, filename: "nedry-ah-ah-ah"),
    Sound(id: "unix-system",     label: "It's a UNIX System!",  emoji: "💾", category: .quote, filename: "unix-system"),
    Sound(id: "must-go-faster",  label: "Must Go Faster",       emoji: "🏎️", category: .quote, filename: "must-go-faster"),

    // ── Music ─────────────────────────────────────────────────────────────
    Sound(id: "jp-theme",        label: "JP Theme",             emoji: "🎵", category: .music, filename: "jurassic-park-theme"),
    Sound(id: "jp-theme-short",  label: "JP Theme (Fast)",      emoji: "⚡", category: .music, filename: "jp-theme-short"),
    Sound(id: "jp-celebration",  label: "JP Celebration",       emoji: "🎉", category: .music, filename: "jp-celebration"),
    Sound(id: "jp-theme-alt",    label: "JP Theme (Alt)",       emoji: "🎶", category: .music, filename: "jp-theme-alt"),
]

// ── Hex color helper ───────────────────────────────────────────────────────
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
