import Foundation
import UIKit
import os.log

class CacheManager: NSObject {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.technicallypilates.cache")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "Cache")
    private var cacheStats: [String: CacheItemStats] = [:]
    private let maxDiskCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxMemoryCacheSize: Int = 20 * 1024 * 1024 // 20MB
    private let cleanupInterval: TimeInterval = 300 // 5 minutes
    
    private override init() {
        super.init()
        setupCache()
        setupCacheMonitoring()
        setupPeriodicCleanup()
    }
    
    // MARK: - Cache Setup
    
    private func setupCache() {
        cache.countLimit = 50
        cache.totalCostLimit = maxMemoryCacheSize
        cache.delegate = self
    }
    
    private func setupCacheMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicCleanup()
        }
    }
    
    private func performPeriodicCleanup() {
        queue.async {
            self.cleanupMemoryCache()
            try? self.cleanupDiskCache()
        }
    }
    
    private func cleanupMemoryCache() {
        cache.removeAllObjects()
        os_log("Memory cache cleared due to cleanup interval", log: logger, type: .debug)
    }
    
    private func cleanupDiskCache() throws {
        let urls = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
        
        let sorted = try urls.sorted {
            let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            return date1 < date2
        }
        
        var totalSize: Int64 = 0
        for url in sorted {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            totalSize += Int64(size)
            if totalSize > maxDiskCacheSize {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    // MARK: - Memory Cache
    
    func setObject(_ object: Any, forKey key: String, cost: Int = 0) {
        queue.async {
            if cost <= self.maxMemoryCacheSize {
                self.cache.setObject(object as AnyObject, forKey: key as NSString, cost: cost)
                self.updateCacheStats(forKey: key, size: cost)
            }
        }
    }
    
    func getObject(forKey key: String) -> Any? {
        let object = cache.object(forKey: key as NSString)
        if object != nil {
            updateCacheStats(forKey: key, hit: true)
        }
        return object
    }
    
    func removeObject(forKey key: String) {
        queue.async {
            self.cache.removeObject(forKey: key as NSString)
            self.cacheStats.removeValue(forKey: key)
        }
    }
    
    // MARK: - Disk Cache
    
    private var diskCacheURL: URL {
        let path = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = path.appendingPathComponent("TechnicallyPilatesCache")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    func saveToDisk(_ data: Data, forKey key: String) throws {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        try data.write(to: fileURL)
        updateCacheStats(forKey: key, size: data.count)
    }
    
    func loadFromDisk(forKey key: String) throws -> Data {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        return try Data(contentsOf: fileURL)
    }
    
    func removeFromDisk(forKey key: String) throws {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        try fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Metadata
    
    private struct CacheMetadata: Codable {
        let expirationDate: Date?
    }
    
    func cacheModel<T: Codable>(_ model: T, forKey key: String, expirationInterval: TimeInterval? = nil) throws {
        let data = try JSONEncoder().encode(model)
        try saveToDisk(data, forKey: key)
        setObject(data, forKey: key, cost: data.count)
        
        if let interval = expirationInterval {
            let expiration = Date().addingTimeInterval(interval)
            let metadata = CacheMetadata(expirationDate: expiration)
            let metadataURL = diskCacheURL.appendingPathComponent("\(key).meta")
            let metaData = try JSONEncoder().encode(metadata)
            try metaData.write(to: metadataURL)
        }
    }
    
    func getCachedModel<T: Codable>(forKey key: String) throws -> T? {
        if isCacheExpired(forKey: key) {
            removeObject(forKey: key)
            try? removeFromDisk(forKey: key)
            return nil
        }
        
        if let data = getObject(forKey: key) as? Data {
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        let data = try loadFromDisk(forKey: key)
        setObject(data, forKey: key, cost: data.count)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func isCacheExpired(forKey key: String) -> Bool {
        let metadataURL = diskCacheURL.appendingPathComponent("\(key).meta")
        if let data = try? Data(contentsOf: metadataURL),
           let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: data),
           let expiration = metadata.expirationDate {
            return Date() > expiration
        }
        return false
    }
    
    func clearMemoryCache() {
        cache.removeAllObjects()
        cacheStats.removeAll()
    }
    
    func clearDiskCache() throws {
        try fileManager.removeItem(at: diskCacheURL)
        try fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        cacheStats.removeAll()
    }
    
    func clearExpiredCache() throws {
        let urls = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
        for url in urls {
            let key = url.lastPathComponent.replacingOccurrences(of: ".meta", with: "")
            if isCacheExpired(forKey: key) {
                try? removeFromDisk(forKey: key)
                try? fileManager.removeItem(at: diskCacheURL.appendingPathComponent("\(key).meta"))
            }
        }
    }
    
    func getExpiredCacheEntriesCount() throws -> Int {
        let urls = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
        return urls.filter {
            let key = $0.lastPathComponent.replacingOccurrences(of: ".meta", with: "")
            return isCacheExpired(forKey: key)
        }.count
    }
    
    private func updateCacheStats(forKey key: String, size: Int? = nil, hit: Bool? = nil) {
        var stats = cacheStats[key] ?? CacheItemStats()
        if let size = size {
            stats.size = size
        }
        if let hit = hit {
            stats.hits += hit ? 1 : 0
            stats.misses += hit ? 0 : 1
        }
        cacheStats[key] = stats
    }
    
    @objc private func handleMemoryWarning() {
        clearMemoryCache()
    }
    
    @objc private func handleAppStateChange() {
        clearMemoryCache()
    }
    
    func getCacheStats() -> CacheStats {
        let itemCount = cacheStats.count
        let totalSize = cacheStats.values.reduce(0) { $0 + $1.size }
        let memoryCacheSize = totalSize
        let hitRate: Double = {
            let hits = cacheStats.values.reduce(0) { $0 + $1.hits }
            let misses = cacheStats.values.reduce(0) { $0 + $1.misses }
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0.0
        }()
        let expiredEntries = (try? getExpiredCacheEntriesCount()) ?? 0
        return CacheStats(itemCount: itemCount, totalSize: totalSize, memoryCacheSize: memoryCacheSize, hitRate: hitRate, expiredEntries: expiredEntries)
    }
}

// MARK: - NSCacheDelegate

extension CacheManager: NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        os_log("Cache evicted an object", log: logger, type: .debug)
    }
}

// MARK: - Supporting Types

struct CacheStats {
    let itemCount: Int
    let totalSize: Int
    let memoryCacheSize: Int
    let hitRate: Double
    var expiredEntries: Int
}

struct CacheItemStats {
    var size: Int = 0
    var hits: Int = 0
    var misses: Int = 0
    var expirationDate: Date? = nil
}

