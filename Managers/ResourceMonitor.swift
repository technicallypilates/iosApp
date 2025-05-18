import Foundation
import UIKit
import os.log

class ResourceMonitor {
    static let shared = ResourceMonitor()
    
    private let queue = DispatchQueue(label: "com.technicallypilates.resourcemonitor")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "ResourceMonitor")
    private var monitoringTimer: Timer?
    private var lastCheck = Date()
    private var lastBatteryLevel: Float = 1.0
    private var lastCPUUsage: Double = 0.0
    private var lastMemoryUsage: Double = 0.0
    
    // Thresholds
    private let cpuThreshold: Double = 80.0 // 80%
    private let memoryThreshold: Double = 80.0 // 80%
    private let batteryDrainThreshold: Double = 5.0 // 5% per minute
    private let temperatureThreshold: Double = 40.0 // 40°C
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkResources()
        }
    }
    
    // MARK: - Resource Monitoring
    
    private func checkResources() {
        queue.async {
            let currentCPU = self.getCurrentCPUUsage()
            let currentMemory = self.getCurrentMemoryUsage()
            let currentBattery = self.getCurrentBatteryDrain()
            let currentTemperature = self.getCurrentTemperature()
            
            // Log resource usage
            self.logResourceUsage(
                cpu: currentCPU,
                memory: currentMemory,
                battery: currentBattery,
                temperature: currentTemperature
            )
            
            // Check for significant changes
            self.checkResourceChanges(
                cpu: currentCPU,
                memory: currentMemory,
                battery: currentBattery,
                temperature: currentTemperature
            )
            
            // Update last values
            self.lastCPUUsage = currentCPU
            self.lastMemoryUsage = currentMemory
            self.lastBatteryLevel = UIDevice.current.batteryLevel
            self.lastCheck = Date()
        }
    }
    
    private func logResourceUsage(cpu: Double, memory: Double, battery: Double, temperature: Double) {
        os_log("""
            Resource Usage:
            CPU: %.1f%%
            Memory: %.1f%%
            Battery Drain: %.1f%%/min
            Temperature: %.1f°C
            """,
            log: logger,
            type: .debug,
            cpu,
            memory,
            battery,
            temperature
        )
    }
    
    private func checkResourceChanges(cpu: Double, memory: Double, battery: Double, temperature: Double) {
        // Check CPU spike
        if cpu - lastCPUUsage > 20 {
            os_log("CPU usage spike detected: %.1f%% -> %.1f%%",
                   log: logger,
                   type: .default,
                   lastCPUUsage,
                   cpu)
        }
        
        // Check memory spike
        if memory - lastMemoryUsage > 20 {
            os_log("Memory usage spike detected: %.1f%% -> %.1f%%",
                   log: logger,
                   type: .default,
                   lastMemoryUsage,
                   memory)
        }
        
        // Check battery drain
        if battery > batteryDrainThreshold {
            os_log("High battery drain detected: %.1f%%/min",
                   log: logger,
                   type: .default,
                   battery)
        }
        
        // Check temperature
        if temperature > temperatureThreshold {
            os_log("High temperature detected: %.1f°C",
                   log: logger,
                   type: .default,
                   temperature)
        }
    }
    
    // MARK: - Resource Measurement
    
    private func getCurrentCPUUsage() -> Double {
        var totalUsage: Double = 0
        var cpuInfo = processor_info_array_t?(nil)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpus,
                                       &cpuInfo,
                                       &numCpuInfo)
        
        if result == KERN_SUCCESS {
            for i in 0..<Int(numCpus) {
                let user = Double(Int(cpuInfo![i * Int(CPU_STATE_MAX) + Int(CPU_STATE_USER)]))
                let system = Double(Int(cpuInfo![i * Int(CPU_STATE_MAX) + Int(CPU_STATE_SYSTEM)]))
                let idle = Double(Int(cpuInfo![i * Int(CPU_STATE_MAX) + Int(CPU_STATE_IDLE)]))
                let total = user + system + idle
                
                if total > 0 {
                    totalUsage += (user + system) / total * 100.0
                }
            }
            
            totalUsage /= Double(Int(numCpus))
        }
        
        return totalUsage
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            let totalMB = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
            return (usedMB / totalMB) * 100.0
        }
        
        return 0
    }
    
    private func getCurrentBatteryDrain() -> Double {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        let currentLevel = device.batteryLevel
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck) / 60.0 // in minutes
        
        if timeSinceLastCheck > 0 {
            let drainRate = (lastBatteryLevel - currentLevel) / Float(timeSinceLastCheck) * 100.0
            return Double(drainRate)
        }
        
        return 0
    }
    
    private func getCurrentTemperature() -> Double {
        // Note: This is a placeholder. iOS doesn't provide direct access to device temperature.
        // In a real app, you would need to estimate temperature based on other metrics
        // or use a third-party solution.
        return 0
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        monitoringTimer?.invalidate()
        setupMonitoring()
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func getResourceReport() -> ResourceReport {
        return ResourceReport(
            cpuUsage: getCurrentCPUUsage(),
            memoryUsage: getCurrentMemoryUsage(),
            batteryDrain: getCurrentBatteryDrain(),
            temperature: getCurrentTemperature()
        )
    }
    
    func processQueuedRequests() {
        queue.async {
            // Process any queued resource monitoring tasks
            self.checkResources()
            
            // Notify observers of resource status
            NotificationCenter.default.post(
                name: .resourceStatusChanged,
                object: nil,
                userInfo: [
                    "report": self.getResourceReport()
                ]
            )
            
            os_log("Processed queued resource monitoring requests", log: self.logger, type: .debug)
        }
    }
}

// MARK: - Supporting Types

struct ResourceReport {
    let cpuUsage: Double
    let memoryUsage: Double
    let batteryDrain: Double
    let temperature: Double
    
    var isHealthy: Bool {
        return cpuUsage < 80 &&
               memoryUsage < 80 &&
               batteryDrain < 5 &&
               temperature < 40
    }
}

extension Notification.Name {
    static let resourceStatusChanged = Notification.Name("resourceStatusChanged")
} 