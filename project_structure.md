# Nudge - Project Structure

## Overview
Nudge is a task management app that connects to Firebase Firestore to fetch, display, and manage tasks.

## Files and Components

### Core Swift Files
- `NudgeApp.swift` - Main app entry point with Firebase configuration
- `ContentView.swift` - Main UI for displaying tasks and managing the task list
- `Task.swift` - Model representing a task entity
- `TaskViewModel.swift` - Business logic and Firebase integration

### Configuration Files
- `GoogleService-Info.plist` - Firebase configuration file
- `Info.plist` - App configuration including network permissions
- `Nudge.entitlements` - App sandbox and permission settings

## Architecture
The app follows MVVM (Model-View-ViewModel) architecture:
- **Model**: Task struct representing the data
- **View**: ContentView and related views for UI
- **ViewModel**: TaskViewModel handling business logic and data operations

## Network and Firebase
- The app connects to Firebase Firestore to fetch and store tasks
- It has offline support with data persistence
- It uses mock data when network connectivity is unavailable
