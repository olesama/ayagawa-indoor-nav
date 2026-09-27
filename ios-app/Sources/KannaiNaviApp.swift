import SwiftUI

@main
struct KannaiNaviApp: App {
    @StateObject private var sensorManager = SensorManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sensorManager)
        }
    }
}

