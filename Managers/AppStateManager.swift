import Foundation
import UIKit
import os.log
import SwiftUI

// MARK: - AppState Model

// Removed duplicate AppState struct. Use the one from Models/Models.swift

// Define QueuedRequest if missing
struct QueuedRequest: Identifiable {
    let id: UUID
    let request: URLRequest
}

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published private(set) var currentState: AppState
    @Published private(set) var isProcessingRequest = false
    
    internal var requestQueue: [QueuedRequest] = []
    internal var activeRequests: Set<String> = []
    
    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.technicallypilates.appstate")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "AppState")
    
    private init() {
        self.currentState = AppState(
            lastActiveDate: Date(),
            currentWorkoutId: nil,
            lastCompletedWorkoutId: nil,
            streakCount: 0,
            totalWorkouts: 0,
            currentRoutineId: nil,
            lastSyncDate: nil,
            pendingOperations: nil
        )
        loadState()
    }
    
    func loadState() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = self.defaults.data(forKey: "appState"),
               let state = try? JSONDecoder().decode(AppState.self, from: data) {
                DispatchQueue.main.async {
                    self.currentState = state
                }
            }
        }
    }
    
    func saveState() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = try? JSONEncoder().encode(self.currentState) {
                self.defaults.set(data, forKey: "appState")
            }
        }
    }
    
    func updateState(_ update: @escaping (inout AppState) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var newState = self.currentState
            update(&newState)
            DispatchQueue.main.async {
                self.currentState = newState
                self.saveState()
            }
        }
    }
    
    func processQueuedRequests() {
        guard !isProcessingRequest else { return }
        isProcessingRequest = true
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            while let request = self.requestQueue.first {
                let requestIdString = request.id.uuidString
                if !self.activeRequests.contains(requestIdString) {
                    self.activeRequests.insert(requestIdString)
                    // You may need to update this handler logic to match your QueuedRequest definition in Models
                    // request.handler { [weak self] in ... }
                    self.requestQueue.removeFirst()
                    self.activeRequests.remove(requestIdString)
                    self.processQueuedRequests()
                    break
                }
            }
            
            self.isProcessingRequest = false
        }
    }
}

// MARK: - NetworkManager Fixes

extension NetworkManager {
    func pauseNonEssentialRequests() {
        queue.async { [weak self] in
            self?.clearRequests(where: { $0.priority == .low })
        }
    }

    func pauseBackgroundTasks() {
        queue.async { [weak self] in
            self?.clearActiveRequests()
        }
    }

    private func clearRequests(where shouldRemove: (NetworkRequest) -> Bool) {
        requestQueue = requestQueue.filter { !shouldRemove($0) }
    }

    private func clearActiveRequests() {
        activeRequests.removeAll()
    }

    func resumeRequests() {
        processQueuedRequests()
    }
}

