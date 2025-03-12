import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // The user ID from your path: gM5WLVoPqUS2VbfmOL9Rk3huDYh1
    private let userId = "gM5WLVoPqUS2VbfmOL9Rk3huDYh1"
    
    init() {
        // Setup Firestore for better offline support
        setupFirestoreSettings()
        
        // Try to fetch real data
        fetchTasks()
        
        // If we don't get data in a reasonable time, use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.tasks.isEmpty == true && self?.isLoading == false {
                self?.useMockData()
            }
        }
    }
    
    func setupFirestoreSettings() {
        // Already set in NudgeApp.swift to avoid multiple configurations
    }
    
    func useMockData() {
        print("Using mock data since Firebase connection failed")
        self.tasks = [
            Task(id: "1", data: [
                "title": "Complete project proposal",
                "description": "Finish the draft and send to team for review",
                "completed": false,
                "priority": 2,
                "createdAt": Timestamp(date: Date())
            ]),
            Task(id: "2", data: [
                "title": "Schedule team meeting",
                "description": "Coordinate with everyone for next sprint planning",
                "completed": true,
                "priority": 1,
                "createdAt": Timestamp(date: Date())
            ]),
            Task(id: "3", data: [
                "title": "Research new APIs",
                "description": "Look into integration options for the mobile app",
                "completed": false,
                "priority": 1,
                "createdAt": Timestamp(date: Date())
            ]),
            Task(id: "4", data: [
                "title": "Fix login bug",
                "description": "Users report session timeout issues",
                "completed": false,
                "priority": 2,
                "createdAt": Timestamp(date: Date().addingTimeInterval(-86400))
            ])
        ]
        self.isLoading = false
    }
    
    deinit {
        // Remove the snapshot listener when the view model is deallocated
        listenerRegistration?.remove()
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
            self.tasks = documents.map { document in
                return Task(id: document.documentID, data: document.data())
            }
            
            // Sort tasks by priority (higher number = higher priority)
            self.tasks.sort { $0.priority > $1.priority }
        }
    }
    
    func addTask(title: String, description: String, dueDate: Date? = nil, priority: Int = 0) {
        var taskData: [String: Any] = [
            "title": title,
            "description": description,
            "completed": false,
            "priority": priority,
            "createdAt": Timestamp(date: Date())
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
    
    func updateTask(id: String, completed: Bool) {
        db.collection("users").document(userId).collection("currentTasks").document(id).updateData([
            "completed": completed
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error updating task: \(error.localizedDescription)"
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
}