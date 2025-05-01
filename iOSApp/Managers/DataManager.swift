import Foundation

class DataManager {
    static let shared = DataManager()
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Save Methods
    
    func save<T: Codable>(_ object: T, to fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
    }
    
    func save<T: Codable>(_ objects: [T], to fileName: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(objects)
        try data.write(to: fileURL)
    }
    
    // MARK: - Load Methods
    
    func load<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
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
} 