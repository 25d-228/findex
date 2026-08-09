import AppKit

final class CommandURLLaunchHandler: NSObject {
    typealias Registration = (CommandURLLaunchHandler) -> Void

    private let dispatch: (URL) -> Void
    private let register: Registration
    private var isInstalled = false

    init(
        dispatch: @escaping (URL) -> Void,
        register: @escaping Registration = { handler in
            NSAppleEventManager.shared().setEventHandler(
                handler,
                andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
                forEventClass: AEEventClass(kInternetEventClass),
                andEventID: AEEventID(kAEGetURL)
            )
        }
    ) {
        self.dispatch = dispatch
        self.register = register
    }

    func install() {
        guard !isInstalled else {
            return
        }

        isInstalled = true
        register(self)
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard
            isInstalled,
            let rawURL = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: rawURL)
        else {
            return
        }

        dispatch(url)
    }
}
