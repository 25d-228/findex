import AppKit
import WebKit

/// Preferences window backed by the bundled shadcn/ui web app
/// (Resources/WebPreferences). Falls back to the native window when the
/// web assets are missing from the bundle.
final class WebPreferencesWindowController: NSWindowController, WKScriptMessageHandler {
    static var bundledPageURL: URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebPreferences")
    }

    static func makeIfAvailable() -> WebPreferencesWindowController? {
        guard let pageURL = bundledPageURL else {
            return nil
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
        contentController.add(self, name: "findex")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        (window?.contentView as? WKWebView)?
            .configuration.userContentController.removeScriptMessageHandler(forName: "findex")
    }

    private static func initialPreferencesScript() -> WKUserScript {
        let preferences: [String: Any] = [
            "terminal": FindexPreferences.terminalBundleIdentifier,
            "editor": FindexPreferences.editorBundleIdentifier,
            "iconSize": FindexPreferences.iconSize,
            "arrangement": FindexPreferences.arrangement.rawValue,
            "view": FindexPreferences.viewStyle.rawValue
        ]

        var json = "{}"
        if let data = try? JSONSerialization.data(withJSONObject: preferences),
           let encoded = String(data: data, encoding: .utf8) {
            json = encoded
        }

        return WKUserScript(
            source: "window.__FINDEX_PREFS__ = \(json);",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == "findex",
            let body = message.body as? [String: Any],
            body["type"] as? String == "save"
        else {
            return
        }

        if let terminal = body["terminal"] as? String, !terminal.isEmpty {
            FindexPreferences.terminalBundleIdentifier = terminal
        }
        if let editor = body["editor"] as? String, !editor.isEmpty {
            FindexPreferences.editorBundleIdentifier = editor
        }
        if let iconSize = body["iconSize"] as? Int {
            FindexPreferences.iconSize = iconSize
        }
        if let rawArrangement = body["arrangement"] as? String,
           let arrangement = FinderArrangement(rawValue: rawArrangement) {
            FindexPreferences.arrangement = arrangement
        }
        if let rawView = body["view"] as? String,
           let viewStyle = FinderViewStyle(rawValue: rawView) {
            FindexPreferences.viewStyle = viewStyle
        }

        NSLog("Findex saved preferences from web UI")
    }
}
