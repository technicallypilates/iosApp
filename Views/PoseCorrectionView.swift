import SwiftUI

struct PoseCorrectionView: View {
    let corrections: [PoseCorrection]
    
    var body: some View {
        VStack {
            if let mainCorrection = corrections.first {
                CorrectionCard(correction: mainCorrection)
            }
            
            if corrections.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(corrections.dropFirst()) { correction in
                            CorrectionCard(correction: correction)
                                .frame(width: 200)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CorrectionCard: View {
    let correction: PoseCorrection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(severityColor)
                Text(correction.message)
                    .font(.headline)
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: correction.severity)
                .tint(severityColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private var iconName: String {
        switch correction.type {
        case .alignment: return "arrow.up.and.down.and.arrow.left.and.right"
        case .angle: return "angle"
        case .stability: return "waveform.path"
        case .symmetry: return "arrow.left.and.right"
        }
    }
    
    private var severityColor: Color {
        switch correction.severity {
        case 0.0..<0.3: return .green
        case 0.3..<0.7: return .yellow
        default: return .red
        }
    }
    
    private var subtitle: String {
        switch correction.type {
        case .alignment: return "Body alignment needs adjustment"
        case .angle: return "Joint angle correction needed"
        case .stability: return "Hold the pose more steadily"
        case .symmetry: return "Balance your body position"
        }
    }
} 