import AppKit
import Darwin

@main
enum CommandURLLaunchHandlerTests {
    static func main() {
        var registrationCount = 0
        var didFinishLaunching = false
        var dispatchPhases: [Bool] = []

        let handler = CommandURLLaunchHandler(
            dispatch: { url in
                guard FindexURL.parse(url) != nil else {
                    return
                }
                dispatchPhases.append(didFinishLaunching)
            },
            register: { _ in
                registrationCount += 1
            }
        )
        let validEvent = urlEvent("findex://run?action=copyFolderPath&folder=/tmp")

        handler.handleURLEvent(validEvent, withReplyEvent: .null())
        expect(dispatchPhases.isEmpty, "dispatched before the URL handler was installed")

        handler.install()
        handler.install()
        expect(registrationCount == 1, "registered the URL handler more than once")

        handler.handleURLEvent(validEvent, withReplyEvent: .null())
        expect(dispatchPhases == [false], "did not dispatch the cold-launch command exactly once before launch completed")

        handler.handleURLEvent(
            urlEvent("findex://run?action=notACommand&folder=/tmp"),
            withReplyEvent: .null()
        )
        expect(dispatchPhases == [false], "dispatched a malformed command URL")

        didFinishLaunching = true
        handler.handleURLEvent(validEvent, withReplyEvent: .null())
        expect(dispatchPhases == [false, true], "changed warm-host command dispatch")

        print("CommandURLLaunchHandlerTests passed")
    }

    private static func urlEvent(_ rawURL: String) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kInternetEventClass),
            eventID: AEEventID(kAEGetURL),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setParam(NSAppleEventDescriptor(string: rawURL), forKeyword: keyDirectObject)
        return event
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("\(message)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
}
