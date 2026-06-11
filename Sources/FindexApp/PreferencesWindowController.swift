import AppKit

final class PreferencesWindowController: NSWindowController {
    private let terminalField = NSTextField(string: FindexPreferences.terminalBundleIdentifier)
    private let editorField = NSTextField(string: FindexPreferences.editorBundleIdentifier)
    private let iconSizeField = NSTextField(string: String(FindexPreferences.iconSize))
    private let arrangementPopup = NSPopUpButton()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Findex Preferences"
        window.center()

        super.init(window: window)
        window.contentView = makeContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeContentView() -> NSView {
        let root = NSView()

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        stack.addArrangedSubview(makeTitle())
        stack.addArrangedSubview(makeRow(label: "Terminal bundle ID", control: terminalField))
        stack.addArrangedSubview(makeRow(label: "Editor bundle ID", control: editorField))
        stack.addArrangedSubview(makeRow(label: "Icon size", control: iconSizeField))
        stack.addArrangedSubview(makeArrangementRow())
        stack.addArrangedSubview(makeButtons())

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 22)
        ])

        return root
    }

    private func makeTitle() -> NSView {
        let label = NSTextField(labelWithString: "Finder toolbar actions")
        label.font = .boldSystemFont(ofSize: 15)
        return label
    }

    private func makeRow(label title: String, control: NSTextField) -> NSView {
        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: 230).isActive = true

        let label = NSTextField(labelWithString: title)
        label.widthAnchor.constraint(equalToConstant: 145).isActive = true

        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    private func makeArrangementRow() -> NSView {
        arrangementPopup.addItems(withTitles: FinderArrangement.allCases.map(\.title))
        if let index = FinderArrangement.allCases.firstIndex(of: FindexPreferences.arrangement) {
            arrangementPopup.selectItem(at: index)
        }

        let label = NSTextField(labelWithString: "Arrange by")
        label.widthAnchor.constraint(equalToConstant: 145).isActive = true

        let row = NSStackView(views: [label, arrangementPopup])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    private func makeButtons() -> NSView {
        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded

        let row = NSStackView(views: [saveButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    @objc private func save() {
        FindexPreferences.terminalBundleIdentifier = terminalField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        FindexPreferences.editorBundleIdentifier = editorField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        FindexPreferences.iconSize = Int(iconSizeField.stringValue) ?? FindexPreferences.iconSize

        let arrangementIndex = arrangementPopup.indexOfSelectedItem
        if FinderArrangement.allCases.indices.contains(arrangementIndex) {
            FindexPreferences.arrangement = FinderArrangement.allCases[arrangementIndex]
        }

        window?.close()
    }
}

