import SwiftUI
import UIKit

@main
struct SpinCounterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // Main container if launched as standalone app; HUD attaches via PassthroughWindow.
            Color.clear
                .ignoresSafeArea()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private var hudWindow: PassthroughWindow?
    private let trackerState = TrackerState()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        DispatchQueue.main.async { [weak self] in
            self?.attachHUD()
        }
        return true
    }

    private func attachHUD() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return
        }

        let window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .statusBar + 100
        window.backgroundColor = .clear

        let hosting = UIHostingController(rootView: HUDView(state: trackerState))
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.isHidden = false
        hudWindow = window
    }
}
