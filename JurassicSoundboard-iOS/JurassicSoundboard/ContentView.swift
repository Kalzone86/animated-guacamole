import SwiftUI

struct ContentView: View {
    @StateObject private var soundManager = SoundManager()

    // Adaptive grid: 2 cols on iPhone, 3-4 on iPad
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 210), spacing: 12)]

    var body: some View {
        ZStack {
            Color(hex: "070f07").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                        ForEach(SoundCategory.allCases, id: \.self) { category in
                            let sounds = allSounds.filter { $0.category == category }
                            if !sounds.isEmpty {
                                Section(header: sectionHeader(category)) {
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(sounds) { sound in
                                            SoundButtonView(sound: sound)
                                                .environmentObject(soundManager)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────
    var header: some View {
        HStack(spacing: 14) {
            Text("🦕")
                .font(.system(size: 38))
            VStack(spacing: 2) {
                Text("JURASSIC")
                    .font(.system(size: 26, weight: .black))
                    .tracking(8)
                    .foregroundColor(Color(hex: "c8a84b"))
                    .shadow(color: Color(hex: "c8a84b").opacity(0.5), radius: 8)
                Text("SOUNDBOARD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(7)
                    .foregroundColor(Color(hex: "5dba5d"))
            }
            Text("🦖")
                .font(.system(size: 38))
                .scaleEffect(x: -1, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(hex: "0d1f0d"), Color(hex: "0a180a")],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Color(hex: "2e7d2e").frame(height: 1)
        }
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }

    // ── Section header ─────────────────────────────────────────────────────
    func sectionHeader(_ category: SoundCategory) -> some View {
        Text(category.rawValue)
            .font(.system(size: 13, weight: .bold))
            .tracking(3)
            .foregroundColor(Color(hex: "5dba5d"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "070f07").opacity(0.95))
    }
}
