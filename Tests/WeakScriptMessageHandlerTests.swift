import Darwin
import WebKit

private final class ScriptMessageTarget: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}

@main
enum WeakScriptMessageHandlerTests {
    static func main() {
        let contentController = WKUserContentController()
        weak var releasedTarget: ScriptMessageTarget?

        do {
            let target = ScriptMessageTarget()
            releasedTarget = target
            contentController.add(WeakScriptMessageHandler(delegate: target), name: "findex")
        }

        guard releasedTarget == nil else {
            fputs("registered script-message bridge retained its target\n", stderr)
            exit(EXIT_FAILURE)
        }

        contentController.removeScriptMessageHandler(forName: "findex")
        print("WeakScriptMessageHandlerTests passed")
    }
}
