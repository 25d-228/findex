import Darwin
import Foundation

@main
enum FinderViewPresetScriptTests {
    static func main() {
        let folderPath = "/tmp/Findex \"quoted\"\\folder"

        assertScript(
            viewStyle: .icon,
            iconSize: 96,
            arrangement: .modificationDate,
            folderPath: folderPath,
            expected: """
            set targetFolder to POSIX file "/tmp/Findex \\\"quoted\\\"\\\\folder" as alias
            tell application "Finder"
                activate
                open targetFolder
                set finderWindow to front Finder window
                set current view of finderWindow to icon view
                tell icon view options of finderWindow
                    set icon size to 96
                    set arrangement to arranged by modification date
                end tell
            end tell
            """
        )

        assertScript(
            viewStyle: .list,
            iconSize: 48,
            arrangement: .kind,
            folderPath: folderPath,
            expected: """
            set targetFolder to POSIX file "/tmp/Findex \\\"quoted\\\"\\\\folder" as alias
            tell application "Finder"
                activate
                open targetFolder
                set finderWindow to front Finder window
                set current view of finderWindow to list view
            end tell
            """
        )

        assertScript(
            viewStyle: .column,
            iconSize: 48,
            arrangement: .kind,
            folderPath: folderPath,
            expected: """
            set targetFolder to POSIX file "/tmp/Findex \\\"quoted\\\"\\\\folder" as alias
            tell application "Finder"
                activate
                open targetFolder
                set finderWindow to front Finder window
                set current view of finderWindow to column view
            end tell
            """
        )

        assertScript(
            viewStyle: .gallery,
            iconSize: 48,
            arrangement: .kind,
            folderPath: folderPath,
            expected: """
            set targetFolder to POSIX file "/tmp/Findex \\\"quoted\\\"\\\\folder" as alias
            tell application "Finder"
                activate
                open targetFolder
                set finderWindow to front Finder window
                set current view of finderWindow to flow view
            end tell
            """
        )

        print("FinderViewPresetScriptTests passed")
    }

    private static func assertScript(
        viewStyle: FinderViewStyle,
        iconSize: Int,
        arrangement: FinderArrangement,
        folderPath: String,
        expected: String
    ) {
        let actual = FinderViewPresetScript.make(
            folderPath: folderPath,
            viewStyle: viewStyle,
            iconSize: iconSize,
            arrangement: arrangement
        )

        guard actual == expected else {
            FileHandle.standardError.write(
                "Script mismatch for \(viewStyle.rawValue) view\nExpected:\n\(expected)\nActual:\n\(actual)\n".data(using: .utf8)!
            )
            exit(EXIT_FAILURE)
        }
    }
}
