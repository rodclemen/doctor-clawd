import AppKit

/// What the Settings window shows: sections of rows, each reading and changing a setting through closures, so the
/// window knows nothing about the app (`OverlayController.settingsSections` builds them).
struct SettingsSection {
    let title: String
    var note: String? = nil
    let rows: [SettingsRow]
}

enum SettingsRow {
    /// A checkbox.
    case toggle(String, note: String? = nil, get: () -> Bool, set: (Bool) -> Void)
    /// A label and a pop-up of choices; when not `shown`, the row is blank but keeps its space, so the window doesn't resize.
    case choice(String, options: [String], shown: () -> Bool = { true }, get: () -> Int, set: (Int) -> Void)
    /// A label, what it says now, and a button.
    case status(String, detail: () -> String, button: () -> String, action: () -> Void)
    /// A button on its own, with a line beside it saying what it does.
    case button(String, note: String, action: () -> Void)
}

/// Clawd Clash's settings in one window: checkboxes, pop-ups and buttons in a few sections. Rebuilt from
/// `sections()` whenever something changes, here or elsewhere (it reloads when it comes to the front).
final class SettingsWindow: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let sections: () -> [SettingsSection]
    /// Actions by control, so a control's target can find its closure.
    private var actions: [ObjectIdentifier: (NSControl) -> Void] = [:]
    private static let width: CGFloat = 480

    init(sections: @escaping () -> [SettingsSection]) {
        self.sections = sections
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 400), styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
        super.init()
        window.title = "Clawd Clash Settings"
        window.isReleasedWhenClosed = false
        window.delegate = self
        reload()
        window.center()
    }

    func show() {
        reload()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowDidBecomeKey(_ notification: Notification) { reload() }

    /// Builds the whole window again from the current settings, keeping its top edge where it is.
    func reload() {
        actions.removeAll()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 22, right: 24)
        for (i, section) in sections().enumerated() {
            if i > 0 {
                let line = NSBox()
                line.boxType = .separator
                stack.addArrangedSubview(line)
                line.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -48).isActive = true
                stack.setCustomSpacing(14, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2])
                stack.setCustomSpacing(14, after: line)
            }
            let title = NSTextField(labelWithString: section.title)
            title.font = .boldSystemFont(ofSize: 13)
            stack.addArrangedSubview(title)
            if let note = section.note { stack.addArrangedSubview(Self.note(note)) }
            for row in section.rows { stack.addArrangedSubview(view(for: row)) }
        }
        let top = window.frame.maxY
        window.contentView = stack
        let size = stack.fittingSize
        window.setContentSize(NSSize(width: Self.width, height: size.height))
        if window.isVisible { window.setFrameTopLeftPoint(NSPoint(x: window.frame.minX, y: top)) }
    }

    private func view(for row: SettingsRow) -> NSView {
        switch row {
        case let .toggle(title, note, get, set):
            let box = NSButton(checkboxWithTitle: title, target: nil, action: nil)
            box.state = get() ? .on : .off
            hook(box) { set(($0 as? NSButton)?.state == .on) }
            guard let note else { return box }
            let indented = NSStackView(views: [Self.note(note, width: Self.width - 48 - 20)])
            indented.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            let v = NSStackView(views: [box, indented])
            v.orientation = .vertical
            v.alignment = .leading
            v.spacing = 2
            return v
        case let .choice(title, options, shown, get, set):
            let popup = NSPopUpButton(frame: .zero, pullsDown: false)
            popup.addItems(withTitles: options)
            popup.selectItem(at: get())
            hook(popup) { set(($0 as? NSPopUpButton)?.indexOfSelectedItem ?? 0) }
            let row = Self.row(Self.label(title), popup)
            if !shown() {
                row.alphaValue = 0
                popup.isEnabled = false
                row.setAccessibilityElement(false)
                row.subviews.forEach { $0.setAccessibilityElement(false) }
            }
            return row
        case let .status(title, detail, button, action):
            let b = NSButton(title: button(), target: nil, action: nil)
            b.bezelStyle = .rounded
            hook(b) { _ in action() }
            let text = Self.label(title)
            let d = NSTextField(labelWithString: detail())
            d.textColor = .secondaryLabelColor
            return Self.row(text, d, b)
        case let .button(title, note, action):
            let b = NSButton(title: title, target: nil, action: nil)
            b.bezelStyle = .rounded
            hook(b) { _ in action() }
            let n = Self.note(note, width: Self.width - 48 - 180)
            let v = NSStackView(views: [b, n])
            v.orientation = .horizontal
            v.alignment = .centerY
            v.spacing = 10
            return v
        }
    }

    /// A row: its label in a fixed column, then the rest.
    private static func row(_ label: NSView, _ rest: NSView...) -> NSView {
        label.widthAnchor.constraint(equalToConstant: 150).isActive = true
        let v = NSStackView(views: [label] + rest)
        v.orientation = .horizontal
        v.alignment = .firstBaseline
        v.spacing = 8
        return v
    }

    private static func label(_ s: String) -> NSTextField {
        let l = NSTextField(labelWithString: s)
        l.alignment = .left
        return l
    }

    /// Small grey text, wrapped to `width`.
    private static func note(_ s: String, width: CGFloat = SettingsWindow.width - 48) -> NSTextField {
        let n = NSTextField(wrappingLabelWithString: s)
        n.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        n.textColor = .secondaryLabelColor
        n.preferredMaxLayoutWidth = width
        n.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
        return n
    }

    /// Runs `action` when the control is used, then shows what changed.
    private func hook(_ control: NSControl, _ action: @escaping (NSControl) -> Void) {
        actions[ObjectIdentifier(control)] = action
        control.target = self
        control.action = #selector(used(_:))
    }

    @objc private func used(_ sender: NSControl) {
        actions[ObjectIdentifier(sender)]?(sender)
        // After the action's own effects (an alert, a hook install) have settled.
        DispatchQueue.main.async { [weak self] in self?.reload() }
    }
}
