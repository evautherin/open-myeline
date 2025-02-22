# iOS 17 SwiftUI Live Activity Project – “Myeline”

**Objective:**  
Develop an iOS 17 SwiftUI app named **“Myeline”** that uses Live Activities to track and display the user’s location in real time. The app must use the new ActivityContent–based APIs exclusively (avoiding any deprecated methods) and CoreLocation’s async sequence (`CLLocationUpdate.liveUpdates()`) for continuous location tracking—even in the background. The app must also support Dynamic Island via a widget extension.

---

## Detailed Requirements

### 1. **Live Activity Setup**

- **Activity Name:** `LocationActivity`
- **Initial State:**  
  - Starts with `nil` latitude and longitude values.
- **Updates:**  
  - Dynamically updates as new location data is received.
- **APIs to Use:**  
  - Create content using:
    ```swift
    ActivityContent(state: initialState, staleDate: nil, relevanceScore: 0.0)
    ```
  - **Start the activity:**
    ```swift
    Activity.request(attributes: LocationActivityAttributes(), content: initialContent, pushType: nil)
    ```
  - **Update the activity:**  
    Call `update(_:)` on the activity with the updated `ActivityContent`.
  - **End the activity:**
    ```swift
    activity.end(finalContent, dismissalPolicy: .immediate)
    ```
- **Important:** Do **not** use any deprecated methods (such as those that directly work with `ContentState`).

### 2. **Location Tracking**

- **Method:**  
  Use the new CoreLocation async sequence:
  ```swift
  for try await update in CLLocationUpdate.liveUpdates() { … }
  ```
- **Processing:**  
  - For each update, extract the optional `CLLocation` from `update.location`.
  - Update the Live Activity with the new latitude and longitude.
  - Handle any thrown errors.
- **Background Execution:**  
  The location tracking must run in an asynchronous Task that continues until the activity is stopped.

### 3. **AppIntents Integration**

Implement two intents that integrate with the Apple Shortcuts app:

- **StartLocationUpdateIntent:**  
  - Conform to both `AppIntent` and `LiveActivityIntent`.
  - In its `perform` method, start the Live Activity and begin tracking by invoking the LiveActivityManager.
  - Include a descriptive title and description.
  
- **StopLocationUpdateIntent:**  
  - Conform to `AppIntent`.
  - In its `perform` method, stop the Live Activity by calling the appropriate method from LiveActivityManager.
  - Also provide a title and description.

### 4. **LiveActivityManager Singleton**

Create a singleton (`LiveActivityManager`) that manages:

- Starting the Live Activity.
- Launching the asynchronous Task that listens for CoreLocation updates.
- Stopping the Live Activity and canceling the task.

### 5. **User Interface**

Develop a simple SwiftUI UI with two buttons:

- **Start Button:**  
  - On tap, execute a Task that calls `perform` on `StartLocationUpdateIntent()`.
- **Stop Button:**  
  - On tap, execute a Task that calls `perform` on `StopLocationUpdateIntent()`.

### 6. **Dynamic Island & Widget Extension**

Build a Widget Extension that supports both the lock screen/banner view and Dynamic Island. The widget should:

- Use `ActivityConfiguration` for `LocationActivityAttributes`.
- Display live location updates:
  - **Lock Screen/Banner:** Show “Latitude” and “Longitude” (or “No Location Available” when nil).
  - **Dynamic Island:**  
    - Expanded: Show compact values (e.g., “Lat:” and “Long:”).
    - Compact/minimal views for other regions.

### 7. **Project Setup & File Organization**

Set up your Xcode project as follows:

1. **Xcode Project Creation:**
   - Create a new SwiftUI App project named **Myeline**.
   - Choose **SwiftUI App** as the Life Cycle, **Swift** as the language, and set the deployment target to iOS 17.

2. **Capabilities & Info.plist Modifications:**
   - In **Signing & Capabilities**, add **Background Modes** and check *Location updates*.
   - In **Info.plist**:
     - Add `NSSupportsLiveActivities` with the value `YES`.
     - Include location usage descriptions like `NSLocationWhenInUseUsageDescription`.

3. **File Organization:**

```
Myeline/
├── MyelineApp.swift
├── ContentView.swift
├── Info.plist
├── Shared/
│   ├── LiveActivityManager.swift
│   ├── LocationActivityAttributes.swift
│   ├── StartLocationUpdateIntent.swift
│   └── StopLocationUpdateIntent.swift
└── LocationActivity/          <-- Widget Extension Target
    ├── LocationActivityWidget.swift
    ├── LocationActivityBundle.swift
    └── Info.plist
```

4. **Shared Code Inclusion:**  
   Place the code files for the Live Activity attributes, manager, and intents in the **Shared** group. Include these files in both the main app and widget extension targets as needed.

---

## 8. **Exact Code Samples**

Below are the exact code samples to be generated in each file.

### A. **LocationActivityAttributes.swift**

```swift
import ActivityKit
import Foundation

struct LocationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var latitude: Double?
        var longitude: Double?
    }
}
```

### B. **LiveActivityManager.swift**

```swift
import Foundation
import ActivityKit
import CoreLocation

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var locationTask: Task<Void, Never>?
    private var activity: Activity<LocationActivityAttributes>? = nil
    
    private init() {}

    /// Starts the Live Activity and begins tracking location.
    func startActivity() async {
        // Create the initial state with nil location values.
        let initialState = LocationActivityAttributes.ContentState(latitude: nil, longitude: nil)
        let initialContent = ActivityContent(state: initialState, staleDate: nil, relevanceScore: 0.0)
        
        do {
            // Start the Live Activity using the new ActivityContent-based API.
            activity = try Activity.request(
                attributes: LocationActivityAttributes(),
                content: initialContent,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
            return
        }
        
        // Start an async Task to process location updates.
        locationTask = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    // Extract the optional location.
                    let location = try update.location
                    let latitude = location?.coordinate.latitude
                    let longitude = location?.coordinate.longitude
                    
                    // Prepare the updated content.
                    let newState = LocationActivityAttributes.ContentState(latitude: latitude, longitude: longitude)
                    let updatedContent = ActivityContent(state: newState, staleDate: nil, relevanceScore: 0.0)
                    
                    // Update the Live Activity.
                    await activity?.update(updatedContent)
                }
            } catch {
                print("Error receiving location updates: \(error)")
            }
        }
    }

    /// Stops the Live Activity and cancels location tracking.
    func stopActivity() async {
        // Cancel the location update task.
        locationTask?.cancel()
        
        // End the Live Activity with final content (resetting location to nil).
        if let currentActivity = activity {
            let finalState = LocationActivityAttributes.ContentState(latitude: nil, longitude: nil)
            let finalContent = ActivityContent(state: finalState, staleDate: nil, relevanceScore: 0.0)
            await currentActivity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}
```

### C. **StartLocationUpdateIntent.swift**

```swift
import AppIntents
import ActivityKit

struct StartLocationUpdateIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Location Updates"
    static var description = IntentDescription("Begin tracking location and start the Live Activity.")

    func perform() async throws -> some IntentResult {
        await LiveActivityManager.shared.startActivity()
        return .result()
    }
}
```

### D. **StopLocationUpdateIntent.swift**

```swift
import AppIntents

struct StopLocationUpdateIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Location Updates"
    static var description = IntentDescription("Stop tracking location and end the Live Activity.")

    func perform() async throws -> some IntentResult {
        await LiveActivityManager.shared.stopActivity()
        return .result()
    }
}
```

### E. **ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Start") {
                Task {
                    _ = try? await StartLocationUpdateIntent().perform()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Stop") {
                Task {
                    _ = try? await StopLocationUpdateIntent().perform()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

### F. **MyelineApp.swift**

```swift
import SwiftUI

@main
struct MyelineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### G. **LocationActivityWidget.swift** (Widget Extension)

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct LocationActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LocationActivityAttributes.self) { context in
            // Lock screen/banner view.
            VStack {
                if let latitude = context.state.latitude, let longitude = context.state.longitude {
                    Text("Latitude: \(latitude)")
                    Text("Longitude: \(longitude)")
                } else {
                    Text("No Location Available")
                }
            }
            .activityBackgroundTint(.blue)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions.
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.latitude != nil ? "Lat: \(context.state.latitude!)" : "Lat: --")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.longitude != nil ? "Long: \(context.state.longitude!)" : "Long: --")
                }
            } compactLeading: {
                Text("Loc")
            } compactTrailing: {
                Text("...")
            } minimal: {
                Text("Loc")
            }
        }
    }
}
```

### H. **LocationActivityBundle.swift** (Widget Bundle)

```swift
import WidgetKit
import SwiftUI

@main
struct LocationActivityBundle: WidgetBundle {
    var body: some Widget {
        LocationActivityWidget()
    }
}
```

---

## 9. **Testing & Verification**

- **Simulator Testing:**  
  Run the app in the iOS 17 simulator. Use **Debug > Location** to simulate location changes and verify that:
  - After tapping **Start**, the Live Activity appears on the lock screen and in the Dynamic Island.
  - The location values update as expected.
  - Tapping **Stop** terminates the activity and cancels background updates.
  
- **Device Testing:**  
  Test on an actual iOS 17 device to ensure background location updates function correctly.

---

By following this prompt exactly, a non-reasoning model will generate the complete code with the same file structure, exact code samples, and organization as outlined above.
