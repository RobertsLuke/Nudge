import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct NudgeApp: App {
    @StateObject private var viewModel = TaskViewModel()
    
    init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            
            // Set Firestore settings for better offline support
            let settings = Firestore.firestore().settings
            settings.isPersistenceEnabled = true
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
            Firestore.firestore().settings = settings
            
            print("Firebase initialized successfully")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}