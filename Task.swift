import Foundation
import FirebaseFirestore

struct Task: Identifiable {
    var id: String
    var title: String
    var description: String
    var completed: Bool
    var inProgress: Bool
    var dueDate: Date?
    var scheduledDate: Date?
    var scheduledStartTime: Date?
    var scheduledEndTime: Date?
    var estimatedMinutes: Int
    var priority: Int
    var frictionLevel: Int // 1-5 scale
    var category: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.title = data["title"] as? String ?? "Untitled Task"
        self.description = data["description"] as? String ?? ""
        self.completed = data["completed"] as? Bool ?? false
        self.inProgress = data["inProgress"] as? Bool ?? false
        
        if let timestamp = data["dueDate"] as? Timestamp {
            self.dueDate = timestamp.dateValue()
        } else {
            self.dueDate = nil
        }
        
        if let timestamp = data["scheduledDate"] as? Timestamp {
            self.scheduledDate = timestamp.dateValue()
        } else {
            self.scheduledDate = nil
        }
        
        if let timestamp = data["scheduledStartTime"] as? Timestamp {
            self.scheduledStartTime = timestamp.dateValue()
        } else {
            self.scheduledStartTime = nil
        }
        
        if let timestamp = data["scheduledEndTime"] as? Timestamp {
            self.scheduledEndTime = timestamp.dateValue()
        } else {
            self.scheduledEndTime = nil
        }
        
        self.estimatedMinutes = data["estimatedMinutes"] as? Int ?? 0
        self.priority = data["priority"] as? Int ?? 0
        self.frictionLevel = data["frictionLevel"] as? Int ?? 1
        self.category = data["category"] as? String ?? "Uncategorized"
        self.tags = data["tags"] as? [String] ?? []
        
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let timestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "description": description,
            "completed": completed,
            "inProgress": inProgress,
            "priority": priority,
            "frictionLevel": frictionLevel,
            "category": category,
            "tags": tags,
            "estimatedMinutes": estimatedMinutes,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let dueDate = dueDate {
            dict["dueDate"] = Timestamp(date: dueDate)
        }
        
        if let scheduledDate = scheduledDate {
            dict["scheduledDate"] = Timestamp(date: scheduledDate)
        }
        
        if let scheduledStartTime = scheduledStartTime {
            dict["scheduledStartTime"] = Timestamp(date: scheduledStartTime)
        }
        
        if let scheduledEndTime = scheduledEndTime {
            dict["scheduledEndTime"] = Timestamp(date: scheduledEndTime)
        }
        
        return dict
    }
    
    // Helper computed properties
    
    var isScheduled: Bool {
        return scheduledDate != nil
    }
    
    var isScheduledForToday: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduledDate)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !completed
    }
    
    var progressPercentage: Double {
        // This would require tracking actual time spent vs estimated
        // For now, just return 100% if completed, 50% if in progress, else 0%
        if completed {
            return 100.0
        } else if inProgress {
            return 50.0
        } else {
            return 0.0
        }
    }
    
    var formattedDuration: String {
        let hours = estimatedMinutes / 60
        let minutes = estimatedMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Status text and color helpers
    
    var statusText: String {
        if completed {
            return "Completed"
        } else if inProgress {
            return "In Progress"
        } else if isScheduled {
            return "Scheduled"
        } else {
            return "To Do"
        }
    }
}
