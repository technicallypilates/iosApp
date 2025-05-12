import SwiftUI

struct ConfettiView: View {
    @State private var confetti: [ConfettiParticle] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confetti) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 6, height: 6)
                        .position(x: particle.position.x, y: animate ? particle.endPosition.y : particle.position.y)
                        .offset(x: animate ? particle.endOffset.width : 0, y: animate ? particle.endOffset.height : 0)
                        .rotationEffect(animate ? particle.endRotation : particle.rotation)
                        .opacity(animate ? 0 : 1)
                        .scaleEffect(animate ? 0.5 : 1)
                        .animation(.easeOut(duration: 2), value: animate)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animate = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    confetti.removeAll()
                    animate = false
                }
            }
            .onDisappear {
                confetti.removeAll()
                animate = false
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        confetti.removeAll()
        for _ in 0..<60 {
            let randomX = CGFloat.random(in: 0...size.width)
            let randomY = CGFloat.random(in: 0...size.height / 2)
            let randomColor = [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.pink, Color.cyan].randomElement()!
            let particle = ConfettiParticle(
                id: UUID(),
                position: CGPoint(x: randomX, y: randomY),
                color: randomColor,
                rotation: Angle.degrees(Double.random(in: 0...360)),
                endRotation: Angle.degrees(Double.random(in: 360...720)),
                endPosition: CGPoint(x: randomX, y: randomY + CGFloat.random(in: 300...600)),
                endOffset: CGSize(width: CGFloat.random(in: -100...100), height: CGFloat.random(in: 100...300))
            )
            confetti.append(particle)
        }
    }
}

struct ConfettiParticle: Identifiable {
    var id: UUID
    var position: CGPoint
    var color: Color
    var rotation: Angle
    var endRotation: Angle
    var endPosition: CGPoint
    var endOffset: CGSize
}

