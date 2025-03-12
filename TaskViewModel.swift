import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var allTasks: [Task] = []
    @Published var todayTasks: [Task] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTab: Int = 0 // 0 = All Tasks, 1 = Today
    @Published var showCompletedTasks: Bool = false
    @Published var selectedTaskID: String?
    @Published var isSchedulingTask: Bool = false
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // User ID from your path
    private let userId = "gM5WLVoPqUS2VbfmOL9Rk3huDYh1"
    
    init() {
        setupFirestoreSettings()
        fetchTasks()
        
        // If we don't get data in a reasonable time, use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.allTasks.isEmpty == true && self?.isLoading == false {
                self?.useMockData()
            }
        }
    }
    
    func setupFirestoreSettings() {
        // Already set in NudgeApp.swift
    }
    
    func useMockData() {
        print("Using mock data since Firebase connection failed")
        
        let now = Date()
        let calendar = Calendar.current
        
        // Create a date that is today at 10 AM
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 10
        components.minute = 0
        let today10AM = calendar.date(from: components) ?? now
        
        // Create a date that is today at 2 PM
        components.hour = 14
        let today2PM = calendar.date(from: components) ?? now
        
        // Create a date that is tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        
        // Sample tasks with more detailed information
        self.allTasks = [
            Task(id: "1", data: [
                "title": "Complete project proposal",
                "description": "Finish the draft and send to team for review",
                "completed": false,
                "inProgress": false,
                "priority": 2,
                "frictionLevel": 3,
                "category": "Work",
                "tags": ["Project", "Writing"],
                "estimatedMinutes": 120,
                "scheduledDate": Timestamp(date: now),
                "scheduledStartTime": Timestamp(date: today10AM),
                "scheduledEndTime": Timestamp(date: today2PM),
                "createdAt": Timestamp(date: calendar.date(byAdding: .day, value: -2, to: now) ?? now),
                "updatedAt": Timestamp(date: now)
            ]),
            Task(id: "2", data: [
                "title": "Schedule team meeting",
                "description": "Coordinate with everyone for next sprint planning",
                "completed": true,
                "inProgress": false,
                "priority": 1,
                "frictionLevel": 1,
                "category": "Work",
                "tags": ["Meeting", "Planning"],
                "estimatedMinutes": 30,
                "createdAt": Timestamp(date: calendar.date(byAdding: .day, value: -1, to: now) ?? now),
                "updatedAt": Timestamp(date: now)
            ]),
            Task(id: "3", data: [
                "title": "Research new APIs",
                "description": "Look into integration options for the mobile app",
                "completed": false,
                "inProgress": true,
                "priority": 1,
                "frictionLevel": 2,
                "category": "Development",
                "tags": ["Research", "Technical"],
                "estimatedMinutes": 90,
                "scheduledDate": Timestamp(date: now),
                "createdAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ]),
            Task(id: "4", data: [
                "title": "Fix login bug",
                "description": "Users report session timeout issues",
                "completed": false,
                "inProgress": false,
                "priority": 2,
                "frictionLevel": 4,
                "category": "Development",
                "tags": ["Bug", "Critical"],
                "estimatedMinutes": 60,
                "scheduledDate": Timestamp(date: tomorrow),
                "dueDate": Timestamp(date: calendar.date(byAdding: .day, value: 2, to: now) ?? now),
                "createdAt": Timestamp(date: calendar.date(byAdding: .day, value: -1, to: now) ?? now),
                "updatedAt": Timestamp(date: now)
            ]),
            Task(id: "5", data: [
                "title": "Workout session",
                "description": "30 min cardio + strength training",
                "completed": false,
                "inProgress": false,
                "priority": 1,
                "frictionLevel": 5,
                "category": "Personal",
                "tags": ["Health", "Routine"],
                "estimatedMinutes": 45,
                "scheduledDate": Timestamp(date: now),
                "createdAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ])
        ]
        
        self.updateTodayTasks()
        self.isLoading = false
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func updateTodayTasks() {
        todayTasks = allTasks.filter { task in
            task.isScheduledForToday
        }.sorted { 
            if let start1 = $0.scheduledStartTime, let start2 = $1.scheduledStartTime {
                return start1 < start2
            } else {
                return $0.priority > $1.priority
            }
        }
    }
    
    func fetchTasks() {
        isLoading = true
        errorMessage = nil
        
        // Reference to the tasks collection for this user
        let tasksRef = db.collection("users").document(userId).collection("currentTasks")
        
        // Set up a snapshot listener to get real-time updates
        listenerRegistration = tasksRef.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching tasks: \(error.localizedDescription)"
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.errorMessage = "No documents found"
                return
            }
            
            // Map the Firestore documents to Task objects
            self.allTasks = documents.map { document in
                return Task(id: document.documentID, data: document.data())
            }
            
            // Sort tasks by priority (higher number = higher priority)
            self.allTasks.sort { $0.priority > $1.priority }
            
            // Update today tasks
            self.updateTodayTasks()
        }
    }
    
    func addTask(title: String, description: String, category: String = "Uncategorized", tags: [String] = [], dueDate: Date? = nil, frictionLevel: Int = 1, estimatedMinutes: Int = 0, priority: Int = 0) {
        var taskData: [String: Any] = [
            "title": title,
            "description": description,
            "completed": false,
            "inProgress": false,
            "priority": priority,
            "frictionLevel": frictionLevel,
            "category": category,
            "tags": tags,
            "estimatedMinutes": estimatedMinutes,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let dueDate = dueDate {
            taskData["dueDate"] = Timestamp(date: dueDate)
        }
        
        db.collection("users").document(userId).collection("currentTasks").addDocument(data: taskData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error adding task: \(error.localizedDescription)"
            }
        }
    }
    
    func updateTask(task: Task) {
        db.collection("users").document(userId).collection("currentTasks").document(task.id).updateData(task.toDict()) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error updating task: \(error.localizedDescription)"
            }
        }
    }
    
    func updateTaskStatus(id: String, completed: Bool, inProgress: Bool = false) {
        db.collection("users").document(userId).collection("currentTasks").document(id).updateData([
            "completed": completed,
            "inProgress": inProgress,
            "updatedAt": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error updating task: \(error.localizedDescription)"
            }
        }
    }
    
    func scheduleTask(id: String, date: Date, startTime: Date? = nil, endTime: Date? = nil) {
        var updateData: [String: Any] = [
            "scheduledDate": Timestamp(date: date),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let startTime = startTime {
            updateData["scheduledStartTime"] = Timestamp(date: startTime)
        }
        
        if let endTime = endTime {
            updateData["scheduledEndTime"] = Timestamp(date: endTime)
        }
        
        db.collection("users").document(userId).collection("currentTasks").document(id).updateData(updateData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error scheduling task: \(error.localizedDescription)"
            } else {
                self?.updateTodayTasks()
            }
        }
    }
    
    func unscheduleTask(id: String) {
        let updateData: [String: Any] = [
            "scheduledDate": FieldValue.delete(),
            "scheduledStartTime": FieldValue.delete(),
            "scheduledEndTime": FieldValue.delete(),
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).collection("currentTasks").document(id).updateData(updateData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error unscheduling task: \(error.localizedDescription)"
            } else {
                self?.updateTodayTasks()
            }
        }
    }
    
    func deleteTask(id: String) {
        db.collection("users").document(userId).collection("currentTasks").document(id).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error deleting task: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Task Filtering Methods
    
    func filterTasks(searchText: String = "", categories: [String] = [], showCompleted: Bool = false) -> [Task] {
        return allTasks.filter { task in
            // Filter by completion status if needed
            if !showCompleted && task.completed {
                return false
            }
            
            // Filter by categories if any are selected
            if !categories.isEmpty && !categories.contains(task.category) {
                return false
            }
            
            // Filter by search text
            if !searchText.isEmpty {
                return task.title.lowercased().contains(searchText.lowercased()) ||
                    task.description.lowercased().contains(searchText.lowercased()) ||
                    task.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
            
            return true
        }
    }
    
    func getTasksByCategory() -> [String: [Task]] {
        var tasksByCategory: [String: [Task]] = [:]
        
        for task in allTasks {
            if tasksByCategory[task.category] == nil {
                tasksByCategory[task.category] = []
            }
            tasksByCategory[task.category]?.append(task)
        }
        
        return tasksByCategory
    }
    
    // MARK: - Notification Methods
    
    func scheduleNotification(for task: Task) {
        guard let scheduledDate = task.scheduledDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.description
        content.sound = getFrictionLevelSound(frictionLevel: task.frictionLevel)
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        // Notify 15 minutes before the scheduled time
        dateComponents.minute = (dateComponents.minute ?? 0) - 15
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(task.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func getFrictionLevelSound(frictionLevel: Int) -> UNNotificationSound {
        switch frictionLevel {
        case 1:
            return UNNotificationSound.default
        case 2:
            return UNNotificationSound.default
        case 3:
            return UNNotificationSound.default
        case 4, 5:
            return UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
        default:
            return UNNotificationSound.default
        }
    }
    
    // Get all unique categories
    var allCategories: [String] {
        Array(Set(allTasks.map { $0.category })).sorted()
    }
    
    // Get all unique tags
    var allTags: [String] {
        Array(Set(allTasks.flatMap { $0.tags })).sorted()
    }
}

// MARK: - Date Helper Extensions

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
