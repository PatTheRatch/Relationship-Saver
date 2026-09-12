import SwiftUI
import MessageUI

/// Wraps the system message composer.
///
/// Using MessageUI rather than an `sms:` URL buys two things. The message body
/// is reliably prefilled, and the delegate reports whether the user actually
/// hit send. That second point matters: V1_SCOPE assumed the app would have to
/// record the interaction optimistically and offer an undo. It does not have
/// to guess here, so it does not.
struct MessageComposerView: UIViewControllerRepresentable {

    let recipients: [String]
    let body: String
    let onFinish: (MessageComposeResult) -> Void

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients.isEmpty ? nil : recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onFinish: (MessageComposeResult) -> Void

        init(onFinish: @escaping (MessageComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func controller(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) { [onFinish] in
                onFinish(result)
            }
        }
    }
}
