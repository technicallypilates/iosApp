import SwiftUI

struct FireTrailView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<20) { index in
                    Circle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: animate
                                ? CGFloat.random(in: 0...geometry.size.height)
                                : geometry.size.height + 10
                        )
                        .animation(
                            Animation.easeOut(duration: Double.random(in: 1...2))
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.05),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

