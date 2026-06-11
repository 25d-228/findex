import AppKit
import FinderSync

@objc(FinderSyncExtension)
final class FinderSyncExtension: FIFinderSync {
    override init() {
        super.init()
        let directoryURLs = Self.monitoredDirectoryURLs()
        FIFinderSyncController.default().directoryURLs = Set(directoryURLs)
        NSLog("Findex FinderSyncExtension started with monitored directories: \(directoryURLs.map(\.path).joined(separator: ", "))")
    }

    override var toolbarItemName: String {
        "Findex"
    }

    override var toolbarItemToolTip: String {
        "Findex Finder actions"
    }

    override var toolbarItemImage: NSImage {
        // Template image: required for the item to render in the macOS 26
        // toolbar style; a full-color icns is silently clipped to overflow.
        FindexGlyphs.toolbarGlyph()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        NSLog("Findex menu requested for kind: \(menuKind.rawValue)")
        let menu = NSMenu(title: "Findex")
        // The toolbar dropdown is ours to style; contextual menu items sit
        // inline between Finder's own, so they stay plain there.
        let styled = menuKind == .toolbarItemMenu

        if styled {
            let header = NSMenuItem(title: "Findex", action: nil, keyEquivalent: "")
            header.attributedTitle = FindexGlyphs.menuTitle("Findex", weight: .bold)
            header.image = FindexGlyphs.creatureIcon()
            header.isEnabled = false
            menu.addItem(header)
            menu.addItem(styled ? FindexGlyphs.textSeparatorItem() : .separator())
        }

        addItem("Copy File Path", action: #selector(copyFilePath), icon: styled ? FindexGlyphs.fileIcon() : nil, styled: styled, to: menu)
        addItem("Copy Folder Path", action: #selector(copyFolderPath), icon: styled ? FindexGlyphs.folderIcon() : nil, styled: styled, to: menu)
        menu.addItem(styled ? FindexGlyphs.textSeparatorItem() : .separator())
        addItem("Open Terminal Here", action: #selector(openTerminal), icon: styled ? FindexGlyphs.terminalIcon() : nil, styled: styled, to: menu)
        addItem("Open in Editor", action: #selector(openEditor), icon: styled ? FindexGlyphs.pencilIcon() : nil, styled: styled, to: menu)
        menu.addItem(styled ? FindexGlyphs.textSeparatorItem() : .separator())
        addItem("Apply View Preset", action: #selector(applyViewPreset), icon: styled ? FindexGlyphs.gridIcon() : nil, styled: styled, to: menu)

        return menu
    }

    override func beginObservingDirectory(at url: URL) {
        NSLog("Findex began observing directory: \(url.path)")
    }

    override func endObservingDirectory(at url: URL) {
        NSLog("Findex ended observing directory: \(url.path)")
    }

    private static func monitoredDirectoryURLs() -> [URL] {
        // Monitoring "/" makes the toolbar menu and context menu items
        // available in every Finder location, including external volumes.
        [URL(fileURLWithPath: "/", isDirectory: true)]
    }

    private func addItem(_ title: String, action: Selector, icon: NSImage?, styled: Bool, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        if styled {
            item.attributedTitle = FindexGlyphs.menuTitle(title)
        }
        item.image = icon
        item.target = self
        menu.addItem(item)
    }

    @objc private func copyFilePath() {
        openHost(command: .copyFilePath)
    }

    @objc private func copyFolderPath() {
        openHost(command: .copyFolderPath)
    }

    @objc private func openTerminal() {
        openHost(command: .openTerminal)
    }

    @objc private func openEditor() {
        openHost(command: .openEditor)
    }

    @objc private func applyViewPreset() {
        openHost(command: .applyViewPreset)
    }

    private func openHost(command: FindexCommand) {
        guard let url = FindexURL.make(command: command, folderURL: currentFolderURL(), fileURLs: selectedItemURLs()) else {
            NSSound.beep()
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func selectedItemURLs() -> [URL] {
        FIFinderSyncController.default().selectedItemURLs() ?? []
    }

    private func currentFolderURL() -> URL? {
        let controller = FIFinderSyncController.default()
        if let targetedURL = controller.targetedURL() {
            return folderURL(for: targetedURL)
        }

        if let selectedURL = controller.selectedItemURLs()?.first {
            return folderURL(for: selectedURL)
        }

        return nil
    }

    private func folderURL(for url: URL) -> URL {
        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return url
        }
        return url.deletingLastPathComponent()
    }
}
