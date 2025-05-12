import Foundation

// MARK: - PoseLogEntry Dictionary Export

extension PoseLogEntry {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

// MARK: - Routine Export / Import

extension Routine {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }

    static func from(dictionary: [String: Any]) throws -> Routine {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Routine.self, from: jsonData)
    }
}

// MARK: - Pose Import

extension Pose {
    static func from(dictionary: [String: Any]) throws -> Pose {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Pose.self, from: jsonData)
    }
}

