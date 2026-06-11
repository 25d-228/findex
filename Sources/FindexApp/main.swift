import AppKit

let app = NSApplication.shared
let delegate = FindexApp()

FindexApp.retainedDelegate = delegate
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
