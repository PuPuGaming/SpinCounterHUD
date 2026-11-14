import UIKit

/// UIWindow subclass that forwards touches outside interactive HUD subviews
/// to underlying windows.
final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        // Ignore hits on the root hosting view's transparent background.
        if hitView == rootViewController?.view {
            return nil
        }
        return hitView
    }
}
