import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var showingPoseLog = false
    
    var body: some View {
        NavigationView {
            VStack {
                CameraPreviewView(
                    poseLabel: viewModel.poseLabel,
                    poseColor: viewModel.poseColor,
                    startDetection: viewModel.startDetection,
                    repCount: viewModel.repCount,
                    logEntries: viewModel.logEntries,
                    selectedRoutine: viewModel.selectedRoutine,
                    currentPoseIndex: viewModel.currentPoseIndex,
                    onNewEntry: { entry in
                        viewModel.addPoseLogEntry(entry)
                    },
                    onComboBroken: {
                        viewModel.resetCombo()
                    }
                )
                
                VStack {
                    HStack {
                        Text("Current Pose:")
                            .font(.headline)
                        Text(viewModel.poseLabel)
                            .foregroundColor(viewModel.poseColor)
                    }
                    
                    Text("Reps: \(viewModel.repCount)")
                        .font(.headline)
                }
                .padding()
                
                Button(action: {
                    showingPoseLog = true
                }) {
                    Text("Show Pose Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Camera")
            .sheet(isPresented: $showingPoseLog) {
                NavigationView {
                    List {
                        ForEach(viewModel.logEntries) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.poseName)
                                    .font(.headline)
                                Text("Reps: \(entry.reps)")
                                    .font(.subheadline)
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .navigationTitle("Pose Log")
                    .navigationBarItems(trailing: Button("Done") {
                        showingPoseLog = false
                    })
                }
            }
        }
    }
}

struct CameraPermissionView: View {
    let status: AVAuthorizationStatus
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(status == .denied ? "Camera Access Denied" : "Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text(status == .denied ?
                 "Please enable camera access in Settings to use pose detection" :
                 "We need camera access to monitor your Pilates poses")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            if status == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Allow Camera Access") {
                    onRequestPermission()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
            .environmentObject(ViewModel())
    }
}



