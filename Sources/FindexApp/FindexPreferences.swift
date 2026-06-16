import AppKit

enum FindexPreferences {
    private enum Key {
        static let terminalBundleIdentifier = "terminalBundleIdentifier"
        static let editorBundleIdentifier = "editorBundleIdentifier"
        static let iconSize = "iconSize"
        static let arrangement = "arrangement"
        static let viewStyle = "viewStyle"
    }

    private enum Default {
        static let terminalBundleIdentifier = "com.apple.Terminal"
        static let editorBundleIdentifier = "com.microsoft.VSCode"
        static let iconSize = 64
    }

    /// Finder icon-view sizes Findex is willing to apply, in points.
    private enum IconSizePoints {
        static let minimum = 16
        static let maximum = 256
    }

    static var terminalBundleIdentifier: String {
        get {
            UserDefaults.standard.string(forKey: Key.terminalBundleIdentifier) ?? Default.terminalBundleIdentifier
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
            // integer(forKey:) returns 0 when unset; iconSize is never stored
            // below the minimum, so 0 unambiguously means "use the default".
            let saved = UserDefaults.standard.integer(forKey: Key.iconSize)
            guard saved != 0 else { return Default.iconSize }
            return min(max(saved, IconSizePoints.minimum), IconSizePoints.maximum)
        }
        set {
            UserDefaults.standard.set(min(max(newValue, IconSizePoints.minimum), IconSizePoints.maximum), forKey: Key.iconSize)
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
            "com.todesktop.230313mzl4w4u92", // Cursor
            "com.microsoft.VSCode",          // Visual Studio Code
            "com.apple.dt.Xcode"             // Xcode
        ]

        for candidate in candidates where AppLocator.hasApplication(bundleIdentifier: candidate) {
            return candidate
        }

        return Default.editorBundleIdentifier
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
