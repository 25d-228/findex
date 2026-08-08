import Darwin
import Foundation

@main
enum PreferenceSaveMessageTests {
    static func main() {
        let validBody: [String: Any] = [
            "type": "save",
            "terminal": "  com.apple.Terminal  ",
            "editor": "\tnvim\n",
            "iconSize": NSNumber(value: 96.0),
            "arrangement": "modificationDate",
            "view": "gallery"
        ]
        let expected = PreferenceSaveMessage(
            terminalBundleIdentifier: "com.apple.Terminal",
            editorBundleIdentifier: "nvim",
            iconSize: 96,
            arrangement: .modificationDate,
            viewStyle: .gallery
        )

        expect(PreferenceSaveMessage.parse(validBody) == expected, "accepts one complete valid message")
        expectRejected(validBody, removing: "terminal")
        expectRejected(validBody, removing: "editor")
        expectRejected(validBody, removing: "iconSize")
        expectRejected(validBody, removing: "arrangement")
        expectRejected(validBody, removing: "view")
        expectRejected(validBody, replacing: "terminal", with: " \n ")
        expectRejected(validBody, replacing: "editor", with: "\t")
        expectRejected(validBody, replacing: "iconSize", with: NSNumber(value: 96.5))
        expectRejected(validBody, replacing: "iconSize", with: NSNumber(value: true))
        expectRejected(validBody, replacing: "arrangement", with: "invalid")
        expectRejected(validBody, replacing: "view", with: "invalid")
        expectRejected(validBody, replacing: "type", with: "invalid")

        print("PreferenceSaveMessageTests passed")
    }

    private static func expectRejected(_ body: [String: Any], removing key: String) {
        var incomplete = body
        incomplete.removeValue(forKey: key)
        expect(PreferenceSaveMessage.parse(incomplete) == nil, "rejects a message missing \(key)")
    }

    private static func expectRejected(_ body: [String: Any], replacing key: String, with value: Any) {
        var invalid = body
        invalid[key] = value
        expect(PreferenceSaveMessage.parse(invalid) == nil, "rejects an invalid \(key)")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("\(message)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
}
