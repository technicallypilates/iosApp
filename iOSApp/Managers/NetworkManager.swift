import Foundation
import Network
import os.log

// MARK: - Network Types and Errors

enum ConnectionType: String {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    var description: String {
        return rawValue.capitalized
    }
}

enum ConnectionQuality: String {
    case excellent
    case good
    case fair
    case poor
    case unknown
    
    var description: String {
        return rawValue.capitalized
    }
}

enum RequestPriority: Int {
    case high = 3
    case normal = 2
    case low = 1
}

struct NetworkRequest: Identifiable {
    let id: UUID
    let request: URLRequest
    var retryCount: Int
    var timeout: TimeInterval
    var priority: RequestPriority
    
    init(request: URLRequest, retryCount: Int = 3, timeout: TimeInterval = 30, priority: RequestPriority = .normal) {
        self.id = UUID()
        self.request = request
        self.retryCount = retryCount
        self.timeout = timeout
        self.priority = priority
    }
}

enum NetworkError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case requestPaused
    case timeout
    case noConnection
    case decodingError
    case unknown
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "com.technicallypilates.network")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "Network")
    private var isConnected = false
    private var connectionType: ConnectionType = .unknown
    private var connectionQuality: ConnectionQuality = .unknown
    internal var requestQueue: [NetworkRequest] = []
    internal var activeRequests: [String: NetworkRequest] = [:]
    private var requestCache: [String: (data: Data, timestamp: Date)] = [:]
    private let maxConcurrentRequests = 2
    private let requestTimeout: TimeInterval = 30
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    private var isPaused = false
    private var backgroundTasks: [String: URLSessionDataTask] = [:]
    
    private init() {
        setupNetworkMonitoring()
        setupCacheCleanup()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.isConnected = path.status == .satisfied
            self.connectionType = self.determineConnectionType(path)
            self.connectionQuality = self.determineConnectionQuality(path)
            
            if self.isConnected {
                self.processQueuedRequests()
            }
            
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: [
                    "isConnected": self.isConnected,
                    "connectionType": self.connectionType,
                    "connectionQuality": self.connectionQuality
                ]
            )
            
            os_log("Network status changed - Connected: %{public}d, Type: %{public}@, Quality: %{public}@",
                   log: self.logger,
                   type: .debug,
                   self.isConnected,
                   self.connectionType.description,
                   self.connectionQuality.description)
        }
        monitor.start(queue: queue)
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
    
    private func determineConnectionQuality(_ path: NWPath) -> ConnectionQuality {
        if path.isExpensive {
            return .poor
        }
        
        if path.isConstrained {
            return .fair
        }
        
        if path.usesInterfaceType(.wifi) {
            return .good
        }
        
        return .unknown
    }
    
    // MARK: - Cache Management
    
    private func setupCacheCleanup() {
        // Clean up cache every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupCache()
        }
    }
    
    private func cleanupCache() {
        queue.async {
            let now = Date()
            self.requestCache = self.requestCache.filter { _, value in
                now.timeIntervalSince(value.timestamp) < self.cacheExpirationInterval
            }
        }
    }
    
    private func getCachedResponse(for request: URLRequest) -> Data? {
        guard let url = request.url?.absoluteString,
              let cached = requestCache[url],
              Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval else {
            return nil
        }
        return cached.data
    }
    
    private func cacheResponse(_ data: Data, for request: URLRequest) {
        guard let url = request.url?.absoluteString else { return }
        requestCache[url] = (data: data, timestamp: Date())
    }
    
    // MARK: - Network Status
    
    var isNetworkAvailable: Bool {
        return isConnected
    }
    
    var currentConnectionType: ConnectionType {
        return connectionType
    }
    
    var currentConnectionQuality: ConnectionQuality {
        return connectionQuality
    }
    
    // MARK: - Advanced Network Requests
    
    struct EmptyResponse: Codable {}
    
    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        guard !isPaused else {
            throw NetworkError.requestPaused
        }
        
                        let (data, response) = try await URLSession.shared.data(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw NetworkError.invalidResponse
                        }
                        
                        guard (200...299).contains(httpResponse.statusCode) else {
                            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                        }
                        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func performRequest(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Request Queue Management
    
    func processQueuedRequests() {
        queue.async {
            self.requestQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
            
            // Process requests concurrently with a limit
            let semaphore = DispatchSemaphore(value: self.maxConcurrentRequests)
            
            for request in self.requestQueue {
                semaphore.wait()
                
                Task {
                    do {
                        try await self.performRequest(request.request)
                        self.requestQueue.removeAll { $0.id == request.id }
                    } catch {
                        os_log("Failed to process queued request: %{public}@",
                               log: self.logger,
                               type: .error,
                               error.localizedDescription)
                    }
                    semaphore.signal()
                }
            }
        }
    }
    
    // MARK: - Advanced Background Tasks
    
    func scheduleBackgroundTask(
        _ task: @escaping () async throws -> Void,
        priority: RequestPriority = .normal
    ) {
        let backgroundTask = NetworkRequest(
            request: URLRequest(url: URL(string: "background://task")!),
            retryCount: 1,
            timeout: 0,
            priority: priority
        )
        
        Task(priority: .background) {
            do {
                // Add delay to prevent immediate execution
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                try await task()
                activeRequests.removeValue(forKey: backgroundTask.id.uuidString)
            } catch {
                os_log("Background task failed: %{public}@",
                       log: logger,
                       type: .error,
                       error.localizedDescription)
            }
        }
    }
    
    // MARK: - Advanced Download Management
    
    func downloadFile(
        from url: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                os_log("Download failed: %{public}@",
                       log: self.logger,
                       type: .error,
                       error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let localURL = localURL else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            completion(.success(localURL))
        }
        
        task.resume()
    }
    
    // MARK: - Advanced Upload Management
    
    func uploadFile(
        _ fileURL: URL,
        to url: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URLResponse, Error>) -> Void
    ) {
        let task = URLSession.shared.uploadTask(with: URLRequest(url: url), fromFile: fileURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                os_log("Upload failed: %{public}@",
                       log: self.logger,
                       type: .error,
                       error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let response = response else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            completion(.success(response))
        }
        
        task.resume()
    }
    
    // MARK: - Network Diagnostics
    
    func getNetworkDiagnostics() -> NetworkDiagnostics {
        return NetworkDiagnostics(
            isConnected: isConnected,
            connectionType: connectionType,
            connectionQuality: connectionQuality,
            queuedRequests: requestQueue.count,
            activeRequests: activeRequests.count
        )
    }
    
    func startMonitoring(_ onStatusChange: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.isConnected = path.status == .satisfied
            self.connectionType = self.determineConnectionType(path)
            self.connectionQuality = self.determineConnectionQuality(path)
            if self.isConnected {
                self.processQueuedRequests()
            }
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: [
                    "isConnected": self.isConnected,
                    "connectionType": self.connectionType,
                    "connectionQuality": self.connectionQuality
                ]
            )
            onStatusChange(self.isConnected)
            os_log("Network status changed - Connected: %{public}d, Type: %{public}@, Quality: %{public}@",
                   log: self.logger,
                   type: .debug,
                   self.isConnected,
                   self.connectionType.description,
                   self.connectionQuality.description)
        }
        monitor.start(queue: queue)
    }
    
    func pauseAllRequests() {
        isPaused = true
        queue.async { [weak self] in
            self?.backgroundTasks.values.forEach { $0.cancel() }
            self?.backgroundTasks.removeAll()
        }
    }
}

struct NetworkDiagnostics {
    let isConnected: Bool
    let connectionType: ConnectionType
    let connectionQuality: ConnectionQuality
    let queuedRequests: Int
    let activeRequests: Int
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
} 