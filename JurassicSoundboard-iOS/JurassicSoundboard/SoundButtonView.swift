import SwiftUI

struct SoundButtonView: View {
    let sound: Sound
    @EnvironmentObject var soundManager: SoundManager

    private var isPlaying: Bool { soundManager.currentlyPlayingId == sound.id }

    var body: some View {
        Button { soundManager.toggle(sound: sound) } label: {
            VStack(spacing: 8) {
                Text(sound.emoji)
                    .font(.system(size: 46))
                    .scaleEffect(isPlaying ? 1.25 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.45), value: isPlaying)

                Text(sound.label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                LinearGradient(
                    colors: sound.category.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPlaying ? sound.category.glowColor : sound.category.glowColor.opacity(0.25),
                        lineWidth: isPlaying ? 2 : 1
                    )
            )
            .shadow(
                color: isPlaying ? sound.category.glowColor.opacity(0.55) : .clear,
                radius: 14
            )
            .scaleEffect(isPlaying ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPlaying)
        }
        .buttonStyle(.plain)
    }
}
