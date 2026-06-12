import AppKit

final class CommandRunner {
    func run(command: FindexCommand, context: FinderContext) {
        let request = FindexRequest(
            command: command,
            folderPath: context.folderPath,
            filePaths: context.filePaths
        )
        run(request: request)
    }

    func run(url: URL) {
        guard let request = FindexURL.parse(url) else {
            NSLog("Findex ignored invalid URL: \(url.absoluteString)")
            return
        }

        run(request: request)
    }

    private func run(request: FindexRequest) {
        switch request.command {
        case .copyFilePath:
            copyFilePaths(from: request)
        case .copyFolderPath:
            copyFolderPath(from: request)
        case .openTerminal:
            openFolder(from: request, bundleIdentifier: FindexPreferences.terminalBundleIdentifier)
        case .openEditor:
            openEditor(from: request)
        case .applyViewPreset:
            applyViewPreset(from: request)
        }
    }

    private func copyFilePaths(from request: FindexRequest) {
        let paths = request.filePaths.isEmpty ? fallbackFolderPaths(from: request) : request.filePaths
        copy(paths)
    }

    private func copyFolderPath(from request: FindexRequest) {
        copy(fallbackFolderPaths(from: request))
    }

    private func fallbackFolderPaths(from request: FindexRequest) -> [String] {
        if let folderPath = request.folderPath, !folderPath.isEmpty {
            return [folderPath]
        }

        return request.filePaths
            .map { URL(fileURLWithPath: $0) }
            .map { folderURL(for: $0).path }
    }

    private func folderURL(for url: URL) -> URL {
        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url
        }
        return url.deletingLastPathComponent()
    }

    private func copy(_ paths: [String]) {
        guard !paths.isEmpty else {
            NSSound.beep()
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
    }

    private func openEditor(from request: FindexRequest) {
        let editor = FindexPreferences.editorBundleIdentifier
        if editor == "nvim" {
            openNvim(from: request)
        } else {
            openFolder(from: request, bundleIdentifier: editor)
        }
    }

    /// Neovim has no app bundle; run it inside the configured terminal.
    /// kitty accepts a working directory and command via `open --args`; other
    /// terminals fall back to opening the folder.
    private func openNvim(from request: FindexRequest) {
        guard let folderPath = fallbackFolderPaths(from: request).first else {
            NSSound.beep()
            return
        }

        let terminal = FindexPreferences.terminalBundleIdentifier
        guard
            terminal == "net.kovidgoyal.kitty",
            let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal)
        else {
            openFolder(from: request, bundleIdentifier: terminal)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", appURL.path, "--args", "--directory", folderPath, "nvim", "."]
        do {
            try process.run()
        } catch {
            NSLog("Findex failed to launch nvim in kitty: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    private func openFolder(from request: FindexRequest, bundleIdentifier: String) {
        guard let folderPath = fallbackFolderPaths(from: request).first else {
            NSSound.beep()
            return
        }

        let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            NSLog("Findex could not find app with bundle identifier \(bundleIdentifier)")
            presentMissingApp(bundleIdentifier: bundleIdentifier)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([folderURL], withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error {
                NSLog("Findex failed to open \(folderPath) with \(bundleIdentifier): \(error.localizedDescription)")
                NSSound.beep()
            }
        }
    }

    private func presentMissingApp(bundleIdentifier: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "App not installed"
            alert.informativeText = "No app with bundle ID “\(bundleIdentifier)” was found. Pick a different one in Findex Preferences."
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    private func applyViewPreset(from request: FindexRequest) {
        guard let folderPath = fallbackFolderPaths(from: request).first else {
            NSSound.beep()
            return
        }

        let script = FinderViewPresetScript.make(folderPath: folderPath)
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error {
            NSLog("Findex failed to apply view preset: \(error)")
            NSSound.beep()
        }
    }
}
