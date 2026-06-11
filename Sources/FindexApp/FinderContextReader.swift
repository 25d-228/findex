import AppKit

struct FinderContext {
    let folderPath: String?
    let filePaths: [String]
}

enum FinderContextReader {
    static func read() -> FinderContext? {
        let script = """
        tell application "Finder"
            set folderPath to ""
            set selectedPaths to {}

            try
                if (count of windows) > 0 then
                    set folderPath to POSIX path of ((target of window 1) as alias)
                else
                    set folderPath to POSIX path of (desktop as alias)
                end if
            end try

            try
                set selectedItems to selection
                repeat with selectedItem in selectedItems
                    set end of selectedPaths to POSIX path of (selectedItem as alias)
                end repeat
            end try

            set AppleScript's text item delimiters to linefeed
            set selectedText to selectedPaths as text
            set AppleScript's text item delimiters to ""
            return folderPath & "\n---FINDEX-SELECTION---\n" & selectedText
        end tell
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue else {
            if let error {
                NSLog("Findex failed to read Finder context: \(error)")
            }
            NSSound.beep()
            return nil
        }

        let marker = "\n---FINDEX-SELECTION---\n"
        let parts = result.components(separatedBy: marker)
        let folderPath = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedText = parts.count > 1 ? parts[1] : ""
        let filePaths = selectedText
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }

        return FinderContext(
            folderPath: folderPath?.isEmpty == false ? folderPath : nil,
            filePaths: filePaths
        )
    }
}
