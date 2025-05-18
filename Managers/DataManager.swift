import Foundation

class DataManager {
    static let shared = DataManager()
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let backupDirectory: URL
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        backupDirectory = documentsDirectory.appendingPathComponent("Backups")
        createBackupDirectoryIfNeeded()
    }
    
    private func createBackupDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Methods
    
    func save<T: Encodable>(_ data: T, to fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(data)
        try data.write(to: fileURL)
    }
    
    func save<T: Codable>(_ objects: [T], to fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(objects)
        try data.write(to: fileURL)
    }
    
    // MARK: - Load Methods
    
    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func load<T: Codable>(_ type: [T].Type, from fileName: String) throws -> [T] {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Delete Methods
    
    func delete(fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - File Existence Check
    
    func fileExists(fileName: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Backup Methods
    
    func backupData() throws {
        let timestamp = Date().timeIntervalSince1970
        let backupFolder = backupDirectory.appendingPathComponent("\(Int(timestamp))")
        try fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        
        let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "json" {
            let fileName = file.lastPathComponent
            let destination = backupFolder.appendingPathComponent(fileName)
            try fileManager.copyItem(at: file, to: destination)
        }
    }
    
    func restoreFromBackup(timestamp: TimeInterval) throws {
        let backupFolder = backupDirectory.appendingPathComponent("\(Int(timestamp))")
        guard fileManager.fileExists(atPath: backupFolder.path) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Backup not found"])
        }
        
        let files = try fileManager.contentsOfDirectory(at: backupFolder, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "json" {
            let fileName = file.lastPathComponent
            let destination = documentsDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: file, to: destination)
        }
    }
    
    // MARK: - Migration Methods
    
    func migrateData() throws {
        // Example migration: Add new fields to existing data
        if fileExists(fileName: "routines.json") {
            var routines: [Routine] = try load([Routine].self, from: "routines.json")
            for i in 0..<routines.count {
                if routines[i].xpReward == 0 {
                    routines[i].xpReward = 50 // Default XP reward
                }
                if routines[i].unlockAccuracy == nil {
                    routines[i].unlockAccuracy = 0.8 // Default unlock accuracy
                }
            }
            try save(routines, to: "routines.json")
        }
    }
    
    // MARK: - Error Handling
    
    func handleCorruptedFile(_ fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Try to load the file
        do {
            let data = try Data(contentsOf: fileURL)
            _ = try JSONDecoder().decode(Data.self, from: data)
        } catch {
            // If loading fails, try to restore from the most recent backup
            let backups = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            if let mostRecentBackup = backups.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first {
                let backupFile = mostRecentBackup.appendingPathComponent(fileName)
                if fileManager.fileExists(atPath: backupFile.path) {
                    try fileManager.removeItem(at: fileURL)
                    try fileManager.copyItem(at: backupFile, to: fileURL)
                }
            }
        }
    }
    
    func clearAllData() throws {
        let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }
    }
}
