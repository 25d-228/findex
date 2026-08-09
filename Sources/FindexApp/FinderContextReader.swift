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

            return {folderPath, selectedPaths}
        end tell
        """

        var error: NSDictionary?
        guard
            let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
            let context = decode(result)
        else {
            if let error {
                NSLog("Findex failed to read Finder context: \(error)")
            }
            NSSound.beep()
            return nil
        }

        return context
    }

    static func decode(_ result: NSAppleEventDescriptor) -> FinderContext? {
        guard
            result.descriptorType == typeAEList,
            result.numberOfItems == 2,
            let folderDescriptor = result.atIndex(1),
            folderDescriptor.descriptorType == typeUnicodeText,
            let folderPath = folderDescriptor.stringValue,
            let selectionDescriptor = result.atIndex(2),
            selectionDescriptor.descriptorType == typeAEList
        else {
            return nil
        }

        var filePaths: [String] = []
        filePaths.reserveCapacity(selectionDescriptor.numberOfItems)
        for index in 0..<selectionDescriptor.numberOfItems {
            guard
                let fileDescriptor = selectionDescriptor.atIndex(index + 1),
                fileDescriptor.descriptorType == typeUnicodeText,
                let filePath = fileDescriptor.stringValue,
                !filePath.isEmpty
            else {
                return nil
            }
            filePaths.append(filePath)
        }

        return FinderContext(
            folderPath: folderPath.isEmpty ? nil : folderPath,
            filePaths: filePaths
        )
    }
}
