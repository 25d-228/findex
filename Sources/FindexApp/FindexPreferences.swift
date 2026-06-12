import AppKit

enum FindexPreferences {
    private enum Key {
        static let terminalBundleIdentifier = "terminalBundleIdentifier"
        static let editorBundleIdentifier = "editorBundleIdentifier"
        static let iconSize = "iconSize"
        static let arrangement = "arrangement"
        static let viewStyle = "viewStyle"
    }

    static var terminalBundleIdentifier: String {
        get {
            UserDefaults.standard.string(forKey: Key.terminalBundleIdentifier) ?? "com.apple.Terminal"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.terminalBundleIdentifier)
        }
    }

    static var editorBundleIdentifier: String {
        get {
            UserDefaults.standard.string(forKey: Key.editorBundleIdentifier) ?? detectedEditorBundleIdentifier()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.editorBundleIdentifier)
        }
    }

    static var iconSize: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: Key.iconSize)
            return saved == 0 ? 64 : min(max(saved, 16), 256)
        }
        set {
            UserDefaults.standard.set(min(max(newValue, 16), 256), forKey: Key.iconSize)
        }
    }

    static var arrangement: FinderArrangement {
        get {
            let rawValue = UserDefaults.standard.string(forKey: Key.arrangement) ?? FinderArrangement.name.rawValue
            return FinderArrangement(rawValue: rawValue) ?? .name
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.arrangement)
        }
    }

    static var viewStyle: FinderViewStyle {
        get {
            let rawValue = UserDefaults.standard.string(forKey: Key.viewStyle) ?? FinderViewStyle.icon.rawValue
            return FinderViewStyle(rawValue: rawValue) ?? .icon
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.viewStyle)
        }
    }

    private static func detectedEditorBundleIdentifier() -> String {
        let candidates = [
            "com.todesktop.230313mzl4w4u92",
            "com.microsoft.VSCode",
            "com.apple.dt.Xcode"
        ]

        for candidate in candidates where AppLocator.hasApplication(bundleIdentifier: candidate) {
            return candidate
        }

        return "com.microsoft.VSCode"
    }
}

enum FinderViewStyle: String, CaseIterable {
    case icon
    case list
    case column
    case gallery

    /// Finder's AppleScript dictionary still calls the gallery view "flow view".
    var appleScriptTerm: String {
        switch self {
        case .icon:
            return "icon view"
        case .list:
            return "list view"
        case .column:
            return "column view"
        case .gallery:
            return "flow view"
        }
    }

    /// Finder's FXPreferredViewStyle code for the global default view.
    var finderPreferredViewStyleCode: String {
        switch self {
        case .icon:
            return "icnv"
        case .list:
            return "Nlsv"
        case .column:
            return "clmv"
        case .gallery:
            return "glyv"
        }
    }

    /// Makes this the default view for folders Finder has no memory of.
    /// Takes effect for newly opened windows without restarting Finder.
    func applyAsFinderGlobalDefault() {
        UserDefaults(suiteName: "com.apple.finder")?
            .set(finderPreferredViewStyleCode, forKey: "FXPreferredViewStyle")
    }
}

enum FinderArrangement: String, CaseIterable {
    case name
    case kind
    case modificationDate
    case none

    var title: String {
        switch self {
        case .name:
            return "Name"
        case .kind:
            return "Kind"
        case .modificationDate:
            return "Modification date"
        case .none:
            return "None"
        }
    }

    var appleScriptTerm: String {
        switch self {
        case .name:
            return "arranged by name"
        case .kind:
            return "arranged by kind"
        case .modificationDate:
            return "arranged by modification date"
        case .none:
            return "not arranged"
        }
    }
}

private enum AppLocator {
    static func hasApplication(bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }
}
