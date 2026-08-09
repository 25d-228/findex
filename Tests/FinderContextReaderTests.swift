import AppKit
import Darwin

@main
enum FinderContextReaderTests {
    static func main() {
        testExactPathPreservation()
        testEmptySelection()
        testEmptyFolder()
        testMalformedResultRejection()
        print("FinderContextReaderTests passed")
    }

    private static func testExactPathPreservation() {
        let folderPath = "  /Folder\n---FINDEX-SELECTION---\n "
        let filePaths = [
            " /leading whitespace",
            "/embedded\nline break",
            "/sentinel/---FINDEX-SELECTION---/text",
            "/trailing whitespace "
        ]
        let result = contextDescriptor(folderPath: folderPath, filePaths: filePaths)

        guard let context = FinderContextReader.decode(result) else {
            fail("rejected valid structured Finder context")
        }
        expect(context.folderPath == folderPath, "changed the folder path")
        expect(context.filePaths == filePaths, "changed selected paths")
    }

    private static func testEmptySelection() {
        let result = contextDescriptor(folderPath: "/Folder", filePaths: [])
        guard let context = FinderContextReader.decode(result) else {
            fail("rejected an empty selection")
        }
        expect(context.filePaths.isEmpty, "did not preserve an empty selection")
    }

    private static func testEmptyFolder() {
        let emptyFolder = contextDescriptor(folderPath: "", filePaths: ["/selected"])
        guard let context = FinderContextReader.decode(emptyFolder) else {
            fail("rejected an empty folder path")
        }
        expect(context.folderPath == nil, "did not map an exactly empty folder path to nil")

        let whitespaceFolder = contextDescriptor(folderPath: " \n ", filePaths: [])
        expect(
            FinderContextReader.decode(whitespaceFolder)?.folderPath == " \n ",
            "discarded a non-empty whitespace folder path"
        )
    }

    private static func testMalformedResultRejection() {
        let flatResult = descriptorList([
            NSAppleEventDescriptor(string: "/Folder"),
            NSAppleEventDescriptor(string: "/not-a-list")
        ])
        expect(FinderContextReader.decode(flatResult) == nil, "accepted a flat result")

        let malformedSelection = descriptorList([
            NSAppleEventDescriptor(string: "/valid"),
            NSAppleEventDescriptor(int32: 7)
        ])
        let partiallyValidResult = descriptorList([
            NSAppleEventDescriptor(string: "/Folder"),
            malformedSelection
        ])
        expect(FinderContextReader.decode(partiallyValidResult) == nil, "accepted a partially malformed selection")
    }

    private static func contextDescriptor(folderPath: String, filePaths: [String]) -> NSAppleEventDescriptor {
        descriptorList([
            NSAppleEventDescriptor(string: folderPath),
            descriptorList(filePaths.map(NSAppleEventDescriptor.init(string:)))
        ])
    }

    private static func descriptorList(_ values: [NSAppleEventDescriptor]) -> NSAppleEventDescriptor {
        let list = NSAppleEventDescriptor.list()
        for (offset, value) in values.enumerated() {
            list.insert(value, at: offset + 1)
        }
        return list
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        fputs("\(message)\n", stderr)
        exit(EXIT_FAILURE)
    }
}
