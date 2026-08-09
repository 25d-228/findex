import AppKit
import WebKit

/// Preferences window backed by the bundled shadcn/ui web app
/// (Resources/WebPreferences).
final class WebPreferencesWindowController: NSWindowController, WKScriptMessageHandler {
    private static var bundledPageURL: URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebPreferences")
    }

    static func make() -> WebPreferencesWindowController {
        guard let pageURL = bundledPageURL else {
            preconditionFailure("Bundled web preferences are missing")
        }
        return WebPreferencesWindowController(pageURL: pageURL)
    }

    private init(pageURL: URL) {
        let contentController = WKUserContentController()
        contentController.addUserScript(Self.initialPreferencesScript())

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Titleless: keep .titled for key-window behavior and window managers,
        // but hide the bar so the page owns the whole surface.
        window.title = "Findex Preferences"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 720, height: 560)
        window.center()
        window.contentView = webView

        super.init(window: window)
        contentController.add(WeakScriptMessageHandler(delegate: self), name: "findex")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        (window?.contentView as? WKWebView)?
            .configuration.userContentController.removeScriptMessageHandler(forName: "findex")
    }

    private static func initialPreferencesScript() -> WKUserScript {
        let bootstrap: [String: Any] = [
            "preferences": FindexPreferences.currentValues.webValue,
            "defaults": FindexPreferences.resolvedDefaults.webValue
        ]

        var json = "{}"
        if let data = try? JSONSerialization.data(withJSONObject: bootstrap),
           let encoded = String(data: data, encoding: .utf8) {
            json = encoded
        }

        return WKUserScript(
            source: """
            const findexBootstrap = \(json);
            window.__FINDEX_PREFS__ = findexBootstrap.preferences;
            window.__FINDEX_DEFAULTS__ = findexBootstrap.defaults;
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == "findex",
            let preferences = PreferenceSaveMessage.parse(message.body)
        else {
            return
        }

        FindexPreferences.terminalBundleIdentifier = preferences.terminalBundleIdentifier
        FindexPreferences.editorBundleIdentifier = preferences.editorBundleIdentifier
        FindexPreferences.iconSize = preferences.iconSize
        FindexPreferences.arrangement = preferences.arrangement
        FindexPreferences.viewStyle = preferences.viewStyle
        preferences.viewStyle.applyAsFinderGlobalDefault()

        NSLog("Findex saved preferences from web UI")
    }
}

private extension FindexPreferences.Values {
    var webValue: [String: Any] {
        [
            "terminal": terminalBundleIdentifier,
            "editor": editorBundleIdentifier,
            "iconSize": iconSize,
            "arrangement": arrangement.rawValue,
            "view": viewStyle.rawValue
        ]
    }
}
