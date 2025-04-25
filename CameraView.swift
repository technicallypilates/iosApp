import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraView: View {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    @Binding var repCount: Int
    @Binding var logEntries: [PoseLogEntry]

    var selectedRoutine: Routine
    var currentPoseIndex: Int
    var onNewEntry: (PoseLogEntry) -> Void

    @State private var comboCount = 0
    @State private var showComboText = false
    @State private var comboTitle = ""
    @State private var showMedal = false
    @State private var sparkleAnimation = false

    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            // Show nothing on simulator
            Color.clear
            #else
            CameraPreviewView(
                poseLabel: $poseLabel,
                poseColor: $poseColor,
                startDetection: $startDetection,
                repCount: $repCount,
                logEntries: $logEntries,
                selectedRoutine: selectedRoutine,
                currentPoseIndex: currentPoseIndex,
                onNewEntry: { entry in
                    onNewEntry(entry)
                    handleComboSuccess()
                },
                onComboBroken: handleComboBreak
            )
            #endif

            VStack {
                Spacer()

                // Removed Pose & Reps overlay (was redundant with ContentView)

                if showComboText {
                    Text(comboTitle)
                        .font(.largeTitle.bold())
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .transition(.scale)
                        .padding(.top)
                }

                if showMedal {
                    Image(systemName: "medal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.yellow)
                        .transition(.scale)
                        .padding(.top)
                }

                Spacer()
            }
        }
        .onAppear {
            sparkleAnimation = true
        }
    }

    private func handleComboSuccess() {
        comboCount += 1

        if comboCount % 5 == 0 {
            comboTitle = titleForCombo(comboCount)
            showComboText = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showComboText = false
            }
            playChimeSound()
        }

        if comboCount % 10 == 0 {
            showMedal = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showMedal = false
            }
        }
    }

    private func handleComboBreak() {
        if comboCount > 0 {
            AudioServicesPlaySystemSound(1104)
        }
        comboCount = 0
    }

    private func titleForCombo(_ count: Int) -> String {
        switch count {
        case 5: return "Nice Streak! 🌟"
        case 10: return "On Fire! 🔥"
        case 20: return "Unstoppable!! 🚀"
        default: return "Combo x\(count)!"
        }
    }

    private func playChimeSound() {
        AudioServicesPlaySystemSound(1025)
    }
}

