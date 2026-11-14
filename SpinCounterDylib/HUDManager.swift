import SwiftUI
import UIKit

@MainActor
@objc(HUDManager)
public final class HUDManager: NSObject {
    private static var hudWindow: PassthroughWindow?
    private static var trackerState: TrackerState?

    @objc public static func start() {
        guard hudWindow == nil else { return }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return
        }

        let state = TrackerState()
        let window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .statusBar + 100
        window.backgroundColor = .clear

        let hosting = UIHostingController(rootView: HUDView(state: state))
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.isHidden = false

        trackerState = state
        hudWindow = window
    }
}
