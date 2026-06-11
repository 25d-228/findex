import Foundation

enum FinderViewPresetScript {
    static func make(folderPath: String) -> String {
        let path = appleScriptString(folderPath)
        let viewStyle = FindexPreferences.viewStyle
        let iconSize = FindexPreferences.iconSize
        let arrangement = FindexPreferences.arrangement.appleScriptTerm

        // Icon size and arrangement are icon-view options; other views just
        // switch the view style.
        let iconViewOptions = viewStyle == .icon ? """

            tell icon view options of finderWindow
                set icon size to \(iconSize)
                set arrangement to \(arrangement)
            end tell
        """ : ""

        return """
        set targetFolder to POSIX file \(path) as alias
        tell application "Finder"
            activate
            open targetFolder
            set finderWindow to front Finder window
            set current view of finderWindow to \(viewStyle.appleScriptTerm)\(iconViewOptions)
        end tell
        """
    }

    private static func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
