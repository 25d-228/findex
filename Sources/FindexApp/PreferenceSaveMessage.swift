import Foundation

struct PreferenceSaveMessage: Equatable {
    let terminalBundleIdentifier: String
    let editorBundleIdentifier: String
    let iconSize: Int
    let arrangement: FinderArrangement
    let viewStyle: FinderViewStyle

    static func parse(_ value: Any) -> PreferenceSaveMessage? {
        guard
            let body = value as? [String: Any],
            body["type"] as? String == "save",
            let rawTerminal = body["terminal"] as? String,
            let rawEditor = body["editor"] as? String,
            let iconSizeNumber = body["iconSize"] as? NSNumber,
            CFGetTypeID(iconSizeNumber) != CFBooleanGetTypeID(),
            let iconSize = iconSizeNumber as? Int,
            let rawArrangement = body["arrangement"] as? String,
            let arrangement = FinderArrangement(rawValue: rawArrangement),
            let rawViewStyle = body["view"] as? String,
            let viewStyle = FinderViewStyle(rawValue: rawViewStyle)
        else {
            return nil
        }

        let terminal = rawTerminal.trimmingCharacters(in: .whitespacesAndNewlines)
        let editor = rawEditor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !terminal.isEmpty, !editor.isEmpty else {
            return nil
        }

        return PreferenceSaveMessage(
            terminalBundleIdentifier: terminal,
            editorBundleIdentifier: editor,
            iconSize: iconSize,
            arrangement: arrangement,
            viewStyle: viewStyle
        )
    }
}
