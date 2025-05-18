import Foundation
import FirebasePerformance
import os.log

class PerformanceManager {
    static let shared = PerformanceManager()
    
    private var traces: [String: FirebasePerformance.Trace] = [:]
    private let queue = DispatchQueue(label: "com.technicallypilates.performance")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "Performance")
    private var metrics: [String: Int] = [:]
    
    private init() {
        setupPerformanceMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupPerformanceMonitoring() {
        // Enable automatic performance monitoring
        Performance.sharedInstance().isDataCollectionEnabled = true
        Performance.sharedInstance().isInstrumentationEnabled = true
    }
    
    // MARK: - Advanced Trace Management
    
    func startTrace(name: String) {
        let trace = Performance.startTrace(name: name)
        traces[name] = trace
        os_log("Started trace: %{public}@", log: logger, type: .debug, name)
    }
    
    func setTraceValue(name: String, value: String, forAttribute attribute: String) {
        guard let trace = traces[name] else { return }
        trace.setValue(value, forAttribute: attribute)
        os_log("Set trace value: %{public}@ = %{public}@", log: logger, type: .debug, attribute, value)
    }
    
    func stopTrace(name: String) {
        guard let trace = traces[name] else { return }
                trace.stop()
        traces.removeValue(forKey: name)
        os_log("Stopped trace: %{public}@", log: logger, type: .debug, name)
    }
    
    func incrementMetric(name: String, by value: Int = 1) {
        metrics[name, default: 0] += value
    }
    
    func setMetric(name: String, value: Int) {
        metrics[name] = value
    }
    
    func getMetric(name: String) -> Int {
        return metrics[name] ?? 0
    }
    
    func resetMetrics() {
        metrics.removeAll()
    }
    
    // MARK: - Advanced Performance Monitoring
    
    func monitorOperation<T>(_ name: String, attributes: [String: String] = [:], operation: () async throws -> T) async throws -> T {
        startTrace(name: name)
        defer { stopTrace(name: name) }
        
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        do {
            let result = try await operation()
            
            let duration = Int(Date().timeIntervalSince(startTime) * 1000)
            let endMemory = getCurrentMemoryUsage()
            let memoryDelta = Int(endMemory - startMemory)
            
            incrementMetric(name: "duration_ms", by: duration)
            incrementMetric(name: "memory_delta_mb", by: memoryDelta)
            
            return result
        } catch {
            incrementMetric(name: "error", by: 1)
            throw error
        }
    }
    
    // MARK: - Advanced Memory Management
    
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
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        return 0
    }
    
    func logMemoryUsage() {
        let usedMB = getCurrentMemoryUsage()
        setMetric(name: "memory_usage_mb", value: Int(usedMB))
        
        os_log("Current memory usage: %.2f MB", log: logger, type: .debug, usedMB)
    }
    
    // MARK: - Advanced Network Monitoring
    
    func monitorNetworkRequest(_ request: URLRequest) -> URLRequest {
        let monitoredRequest = request
        if let url = request.url {
            let traceName = "network_\(url.path)"
            startTrace(name: traceName)
            incrementMetric(name: "request_size", by: request.httpBody?.count ?? 0)
        }
        return monitoredRequest
    }
    
    func completeNetworkRequest(_ request: URLRequest, response: URLResponse?, error: Error?) {
        if let url = request.url {
            let traceName = "network_\(url.path)"
            
            if let httpResponse = response as? HTTPURLResponse {
                incrementMetric(name: "status_code", by: httpResponse.statusCode)
                incrementMetric(name: "response_size", by: Int(httpResponse.expectedContentLength))
            }
            
            if let error = error {
                incrementMetric(name: "error", by: 1)
                os_log("Network request failed: %{public}@", log: logger, type: .error, error.localizedDescription)
            }
            
            stopTrace(name: traceName)
        }
    }
    
    // MARK: - Advanced Database Performance
    
    func monitorDatabaseOperation(_ operation: String, attributes: [String: String] = [:]) -> String {
        let traceName = "db_\(operation)"
        startTrace(name: traceName)
        return traceName
    }
    
    func completeDatabaseOperation(_ traceName: String, success: Bool, documentCount: Int = 0) {
        incrementMetric(name: "success", by: success ? 1 : 0)
        incrementMetric(name: "document_count", by: documentCount)
        stopTrace(name: traceName)
    }
    
    // MARK: - Advanced UI Performance
    
    func monitorViewLoad(_ viewName: String) {
        startTrace(name: "view_load_\(viewName)")
    }
    
    func completeViewLoad(_ viewName: String, loadTime: TimeInterval) {
        let traceName = "view_load_\(viewName)"
        incrementMetric(name: "load_time_ms", by: Int(loadTime * 1000))
        stopTrace(name: traceName)
    }
    
    func monitorAnimation(_ animationName: String) {
        startTrace(name: "animation_\(animationName)")
    }
    
    func completeAnimation(_ animationName: String, duration: TimeInterval) {
        let traceName = "animation_\(animationName)"
        incrementMetric(name: "duration_ms", by: Int(duration * 1000))
        stopTrace(name: traceName)
    }
    
    // MARK: - Performance Reporting
    
    func generatePerformanceReport() -> [String: Any] {
        var report: [String: Any] = [:]
        
        queue.sync {
            report["active_traces"] = traces.keys
            report["metrics"] = metrics
            report["memory_usage"] = getCurrentMemoryUsage()
        }
        
        return report
    }
} 