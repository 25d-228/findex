import AppKit

final class FindexServicesProvider: NSObject {
    private let commandRunner: CommandRunner

    init(commandRunner: CommandRunner) {
        self.commandRunner = commandRunner
        super.init()
    }

    @objc func copyFilePathService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.copyFilePath, pasteboard: pasteboard, error: error)
    }

    @objc func copyFolderPathService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.copyFolderPath, pasteboard: pasteboard, error: error)
    }

    @objc func openTerminalService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.openTerminal, pasteboard: pasteboard, error: error)
    }

    @objc func openEditorService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.openEditor, pasteboard: pasteboard, error: error)
    }

    @objc func applyViewPresetService(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        run(.applyViewPreset, pasteboard: pasteboard, error: error)
    }

    private func run(
        _ command: FindexCommand,
        pasteboard: NSPasteboard,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let fileURLs = readFileURLs(from: pasteboard)
        guard !fileURLs.isEmpty else {
            error.pointee = "Findex needs a selected Finder item."
            NSSound.beep()
            return
        }

        let folderPath = folderPath(for: fileURLs.first)
        let context = FinderContext(
            folderPath: folderPath,
            filePaths: fileURLs.map(\.path)
        )
        commandRunner.run(command: command, context: context)
    }

    private func readFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return urls
        }

        let fileNamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: fileNamesType) as? [String] {
            return paths.map { URL(fileURLWithPath: $0) }
        }

        if let fileURLString = pasteboard.string(forType: .fileURL),
           let url = URL(string: fileURLString) {
            return [url]
        }

        if let text = pasteboard.string(forType: .string) {
            let urls = text
                .split(whereSeparator: \.isNewline)
                .compactMap { fileURL(from: String($0)) }
            if !urls.isEmpty {
                return urls
            }
        }

        return []
    }

    private func fileURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        return nil
    }

    private func folderPath(for url: URL?) -> String? {
        guard let url else {
            return nil
        }

        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url.path
        }

        return url.deletingLastPathComponent().path
    }
}
