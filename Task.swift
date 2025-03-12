import Foundation
import FirebaseFirestore

struct Task: Identifiable {
    var id: String
    var title: String
    var description: String
    var completed: Bool
    var dueDate: Date?
    var priority: Int
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.title = data["title"] as? String ?? "Untitled Task"
        self.description = data["description"] as? String ?? ""
        self.completed = data["completed"] as? Bool ?? false
        if let timestamp = data["dueDate"] as? Timestamp {
            self.dueDate = timestamp.dateValue()
        } else {
            self.dueDate = nil
        }
        self.priority = data["priority"] as? Int ?? 0
    }
}