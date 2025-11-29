import SwiftUI
import UIKit

class ShareManager {
    static let shared = ShareManager()

    private init() {}

    func shareResults(text: String, from viewController: UIViewController? = nil) {
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // For iPad
        if let popoverController = activityViewController.popoverPresentationController,
           let sourceView = viewController?.view {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(
                x: sourceView.bounds.midX,
                y: sourceView.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        // Present from root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(activityViewController, animated: true) {
                AnalyticsManager.shared.track(.shareAttempted)
                SoundManager.shared.playHaptic(.medium)
            }
        }
    }
}

// SwiftUI wrapper
struct ShareButton: View {
    let shareText: String
    var label: String = "Share"
    var icon: String = "square.and.arrow.up"

    var body: some View {
        Button(action: {
            ShareManager.shared.shareResults(text: shareText)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color("C_PureWhite"))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(Color("C_WarmTeal"))
            )
            .overlay(
                Capsule()
                    .stroke(Color("C_WarmTeal"), lineWidth: 1.2)
            )
            .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
