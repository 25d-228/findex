import AppKit
import Carbon

final class FindexApp: NSObject, NSApplicationDelegate {
    static var retainedDelegate: FindexApp?

    private let commandRunner = CommandRunner()
    private lazy var commandURLLaunchHandler = CommandURLLaunchHandler { [commandRunner] url in
        commandRunner.run(url: url)
    }
    private lazy var servicesProvider = FindexServicesProvider(commandRunner: commandRunner)
    private var preferencesWindowController: WebPreferencesWindowController?
    private var statusItem: NSStatusItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        commandURLLaunchHandler.install()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installServices()
        installStatusItem()
        installMainMenu()
    }

    /// Accessory apps have no main menu, so standard shortcuts (Cmd+W, Cmd+Q,
    /// Cmd+C/V in text fields) do nothing while the preferences window is key.
    private func installMainMenu() {
        let mainMenu = NSMenu()

        // AppKit shows the first submenu under the app name, ignoring its title.
        mainMenu.addItem(submenuItem(title: "") { menu in
            menu.addItem(withTitle: "Quit Findex", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        })

        mainMenu.addItem(submenuItem(title: "File") { menu in
            menu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        })

        mainMenu.addItem(submenuItem(title: "Edit") { menu in
            menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
            menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        })

        // Window needs its menu kept around for NSApp.windowsMenu, so it is
        // built inline rather than through the helper.
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        let windowItem = NSMenuItem()
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    /// Wraps a populated submenu in the top-level NSMenuItem that hosts it.
    private func submenuItem(title: String, build: (NSMenu) -> Void) -> NSMenuItem {
        let submenu = NSMenu(title: title)
        build(submenu)
        let item = NSMenuItem()
        item.submenu = submenu
        return item
    }

    private func installServices() {
        NSApp.servicesProvider = servicesProvider
        NSUpdateDynamicServices()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = FindexGlyphs.toolbarGlyph()
        item.button?.toolTip = "Findex"

        let menu = NSMenu()

        let header = NSMenuItem(title: "Findex", action: nil, keyEquivalent: "")
        header.attributedTitle = FindexGlyphs.menuTitle("Findex", weight: .bold)
        header.image = FindexGlyphs.creatureIcon()
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(FindexGlyphs.separatorItem())

        menu.addItem(FindexGlyphs.menuItem("Copy File Path", action: #selector(copyFilePath), target: self, icon: FindexGlyphs.fileIcon()))
        menu.addItem(FindexGlyphs.menuItem("Copy Folder Path", action: #selector(copyFolderPath), target: self, icon: FindexGlyphs.folderIcon()))
        menu.addItem(FindexGlyphs.separatorItem())
        menu.addItem(FindexGlyphs.menuItem("Open Terminal Here", action: #selector(openTerminal), target: self, icon: FindexGlyphs.terminalIcon()))
        menu.addItem(FindexGlyphs.menuItem("Open in Editor", action: #selector(openEditor), target: self, icon: FindexGlyphs.pencilIcon()))
        menu.addItem(FindexGlyphs.separatorItem())
        menu.addItem(FindexGlyphs.menuItem("Apply View Preset", action: #selector(applyViewPreset), target: self, icon: FindexGlyphs.gridIcon()))
        menu.addItem(FindexGlyphs.separatorItem())
        menu.addItem(FindexGlyphs.menuItem("Preferences...", action: #selector(showPreferences), target: self, icon: FindexGlyphs.slidersIcon(), keyEquivalent: ","))
        menu.addItem(FindexGlyphs.separatorItem())
        menu.addItem(FindexGlyphs.menuItem("Quit Findex", action: #selector(quit), target: self, icon: FindexGlyphs.crossIcon(), keyEquivalent: "q"))

        item.menu = menu

        statusItem = item
    }

    @objc private func copyFilePath() {
        runFinderCommand(.copyFilePath)
    }

    @objc private func copyFolderPath() {
        runFinderCommand(.copyFolderPath)
    }

    @objc private func openTerminal() {
        runFinderCommand(.openTerminal)
    }

    @objc private func openEditor() {
        runFinderCommand(.openEditor)
    }

    @objc private func applyViewPreset() {
        runFinderCommand(.applyViewPreset)
    }

    private func runFinderCommand(_ command: FindexCommand) {
        guard let context = FinderContextReader.read() else {
            return
        }

        commandRunner.run(command: command, context: context)
    }

    @objc private func showPreferences() {
        let controller: WebPreferencesWindowController
        if let existing = preferencesWindowController, existing.window?.isVisible == true {
            controller = existing
        } else {
            // Recreated per open so the page always reflects current defaults.
            let webController = WebPreferencesWindowController.make()
            preferencesWindowController = webController
            controller = webController
        }

        // Become a regular app while a window is visible so window managers
        // (yabai) track and tile it; accessory apps are invisible to them.
        NSApp.setActivationPolicy(.regular)
        controller.showWindow(nil)
        if let window = controller.window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(preferencesWindowWillClose(_:)),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func preferencesWindowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
            if preferencesWindowController?.window === window {
                preferencesWindowController = nil
            }
        }
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

}
