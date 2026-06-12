import AppKit

/// Code-drawn pixel glyphs shared by the host app (status bar, menus) and the
/// Finder Sync extension (toolbar button, toolbar menu). Template images tint
/// with the menu bar / toolbar appearance; the creature is full color.
enum FindexGlyphs {
    static func menuTitle(_ title: String, weight: NSFont.Weight = .medium) -> NSAttributedString {
        NSAttributedString(string: title, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: weight),
            .kern: 0.4
        ])
    }

    static func menuItem(
        _ title: String,
        action: Selector?,
        target: AnyObject?,
        icon: NSImage?,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.attributedTitle = menuTitle(title)
        item.image = icon
        item.target = target
        return item
    }

    /// macOS 26 draws NSMenuItem.separator() as empty space in Finder Sync
    /// menus; these are visible rules instead.

    /// Compact rule: a 7pt custom view. Works in same-process menus (status
    /// item); custom views do not survive the XPC hop into Finder.
    static func separatorItem() -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let view = MenuRuleView(frame: NSRect(x: 0, y: 0, width: 180, height: 7))
        view.autoresizingMask = [.width]
        item.view = view
        item.isEnabled = false
        return item
    }

    private final class MenuRuleView: NSView {
        override var intrinsicContentSize: NSSize {
            NSSize(width: NSView.noIntrinsicMetric, height: 7)
        }

        override func draw(_ dirtyRect: NSRect) {
            NSColor.tertiaryLabelColor.setFill()
            NSRect(x: 13, y: bounds.midY - 0.5, width: bounds.width - 26, height: 1).fill()
        }
    }

    /// The Findex folder silhouette with the pixel creature's eyes and mouth
    /// knocked out — used for the Finder toolbar button and the status item.
    static func toolbarGlyph() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            let folder = NSBezierPath()
            folder.move(to: NSPoint(x: 2, y: 15.5))
            folder.line(to: NSPoint(x: 2, y: 5))
            folder.line(to: NSPoint(x: 8, y: 5))
            folder.line(to: NSPoint(x: 9.8, y: 7))
            folder.line(to: NSPoint(x: 16, y: 7))
            folder.line(to: NSPoint(x: 16, y: 15.5))
            folder.close()
            NSColor.black.setFill()
            folder.fill()

            if let context = NSGraphicsContext.current?.cgContext {
                context.clear(CGRect(x: 5, y: 9, width: 2, height: 2))
                context.clear(CGRect(x: 11, y: 9, width: 2, height: 2))
                context.clear(CGRect(x: 7, y: 12.5, width: 4, height: 1.5))
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func pixelIcon(_ draw: @escaping (CGContext) -> Void) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return true }
            context.setFillColor(NSColor.black.cgColor)
            draw(context)
            return true
        }
        image.isTemplate = true
        return image
    }

    static func folderIcon() -> NSImage {
        pixelIcon { ctx in
            let folder = CGMutablePath()
            folder.move(to: CGPoint(x: 2, y: 14))
            folder.addLine(to: CGPoint(x: 2, y: 4.5))
            folder.addLine(to: CGPoint(x: 7, y: 4.5))
            folder.addLine(to: CGPoint(x: 8.6, y: 6.3))
            folder.addLine(to: CGPoint(x: 14, y: 6.3))
            folder.addLine(to: CGPoint(x: 14, y: 14))
            folder.closeSubpath()
            ctx.addPath(folder)
            ctx.fillPath()
        }
    }

    static func fileIcon() -> NSImage {
        pixelIcon { ctx in
            let page = CGMutablePath()
            page.move(to: CGPoint(x: 4, y: 14.5))
            page.addLine(to: CGPoint(x: 4, y: 1.5))
            page.addLine(to: CGPoint(x: 9.5, y: 1.5))
            page.addLine(to: CGPoint(x: 12, y: 4))
            page.addLine(to: CGPoint(x: 12, y: 14.5))
            page.closeSubpath()
            ctx.addPath(page)
            ctx.fillPath()
            ctx.clear(CGRect(x: 5.8, y: 6.5, width: 4.4, height: 1.2))
            ctx.clear(CGRect(x: 5.8, y: 9, width: 4.4, height: 1.2))
            ctx.clear(CGRect(x: 5.8, y: 11.5, width: 2.8, height: 1.2))
        }
    }

    static func terminalIcon() -> NSImage {
        pixelIcon { ctx in
            ctx.fill(CGRect(x: 1.5, y: 3, width: 13, height: 10.5))
            ctx.clear(CGRect(x: 3.8, y: 5.8, width: 1.4, height: 1.4))
            ctx.clear(CGRect(x: 5.2, y: 7.2, width: 1.4, height: 1.4))
            ctx.clear(CGRect(x: 3.8, y: 8.6, width: 1.4, height: 1.4))
            ctx.clear(CGRect(x: 8, y: 10, width: 3.5, height: 1.4))
        }
    }

    static func pencilIcon() -> NSImage {
        pixelIcon { ctx in
            ctx.fill(CGRect(x: 11, y: 1.5, width: 3, height: 3))
            ctx.fill(CGRect(x: 9, y: 3.5, width: 3, height: 3))
            ctx.fill(CGRect(x: 7, y: 5.5, width: 3, height: 3))
            ctx.fill(CGRect(x: 5, y: 7.5, width: 3, height: 3))
            ctx.fill(CGRect(x: 3, y: 9.5, width: 3, height: 3))
            ctx.fill(CGRect(x: 2, y: 12, width: 2.5, height: 2.5))
        }
    }

    static func gridIcon() -> NSImage {
        pixelIcon { ctx in
            ctx.fill(CGRect(x: 2.5, y: 2.5, width: 4.5, height: 4.5))
            ctx.fill(CGRect(x: 9, y: 2.5, width: 4.5, height: 4.5))
            ctx.fill(CGRect(x: 2.5, y: 9, width: 4.5, height: 4.5))
            ctx.fill(CGRect(x: 9, y: 9, width: 4.5, height: 4.5))
        }
    }

    static func slidersIcon() -> NSImage {
        pixelIcon { ctx in
            ctx.fill(CGRect(x: 2, y: 4, width: 12, height: 1.4))
            ctx.fill(CGRect(x: 9, y: 2.8, width: 3, height: 3.8))
            ctx.fill(CGRect(x: 2, y: 8.5, width: 12, height: 1.4))
            ctx.fill(CGRect(x: 4, y: 7.3, width: 3, height: 3.8))
            ctx.fill(CGRect(x: 2, y: 13, width: 12, height: 1.4))
            ctx.fill(CGRect(x: 10, y: 11.8, width: 3, height: 3.8))
        }
    }

    static func crossIcon() -> NSImage {
        pixelIcon { ctx in
            for i in 0..<5 {
                let offset = CGFloat(i) * 2.2
                ctx.fill(CGRect(x: 3 + offset, y: 3 + offset, width: 2.2, height: 2.2))
                ctx.fill(CGRect(x: 11.8 - offset, y: 3 + offset, width: 2.2, height: 2.2))
            }
        }
    }

    /// The pixel creature from the app icon, in color, for menu headers.
    static func creatureIcon() -> NSImage {
        NSImage(size: NSSize(width: 16, height: 16), flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }
            let ink = NSColor(srgbRed: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor
            let pink = NSColor(srgbRed: 0.961, green: 0.647, blue: 0.722, alpha: 1).cgColor
            let white = NSColor.white.cgColor

            ctx.setFillColor(ink)
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            ctx.fill(CGRect(x: 12, y: 0, width: 4, height: 4))
            ctx.fill(CGRect(x: 0, y: 4, width: 16, height: 4))
            ctx.setFillColor(pink)
            ctx.fill(CGRect(x: 2, y: 2, width: 2, height: 2))
            ctx.fill(CGRect(x: 12, y: 2, width: 2, height: 2))
            ctx.setFillColor(white)
            ctx.fill(CGRect(x: 4, y: 6, width: 2, height: 2))
            ctx.fill(CGRect(x: 10, y: 6, width: 2, height: 2))
            ctx.fill(CGRect(x: 2, y: 8, width: 12, height: 4))
            ctx.fill(CGRect(x: 4, y: 12, width: 8, height: 3))
            ctx.setFillColor(ink)
            ctx.fill(CGRect(x: 4, y: 8, width: 2, height: 2))
            ctx.fill(CGRect(x: 10, y: 8, width: 2, height: 2))
            ctx.fill(CGRect(x: 7, y: 12.4, width: 2, height: 1.6))
            return true
        }
    }
}
