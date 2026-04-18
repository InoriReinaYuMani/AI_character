import CompanionCore
import CompanionFeature
import Foundation

#if canImport(SwiftUI)
import SwiftUI

@main
@MainActor
struct CompanionDemoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: CompanionViewModel
    private let store: JSONCompanionStateStore

    init() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CompanionDemo/state.json")
        self.store = JSONCompanionStateStore(fileURL: url)

        var seed = CompanionCoordinator()
        try? seed.loadState(from: store)
        let hasData = seed.stats().totalQuestions > 0
        _viewModel = StateObject(
            wrappedValue: CompanionViewModel(
                coordinator: seed,
                hasCompletedOnboarding: hasData
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            CompanionRootView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .background {
                try? viewModel.coordinator.saveState(to: store)
            }
        }
    }
}

#else
@main
struct CompanionDemoApp {
    static func main() {
        print("CompanionDemoApp is intended for iOS/macOS with SwiftUI.")
    }
}
#endif
