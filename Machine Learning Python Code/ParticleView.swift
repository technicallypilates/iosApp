import SwiftUI

struct ParticleView: View {
    @State private var particles: [FireParticle] = []
    var isActive: Bool

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { active in
            if active {
                startEmitting()
            } else {
                stopEmitting()
            }
        }
    }

    private func startEmitting() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
                return
            }
            let newParticle = FireParticle(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: 100...300), y: CGFloat.random(in: 200...400)),
                color: [.orange, .red, .yellow].randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: Double.random(in: 0.4...0.9),
                blur: CGFloat.random(in: 1...4)
            )
            particles.append(newParticle)
            if particles.count > 100 {
                particles.removeFirst()
            }
        }
    }

    private func stopEmitting() {
        particles.removeAll()
    }
}

struct FireParticle: Identifiable {
    var id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

