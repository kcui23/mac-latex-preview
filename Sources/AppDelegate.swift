import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var selectionMonitor: SelectionMonitor!
    private var overlayWindow: OverlayWindow!
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permission (shows system prompt if not granted)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        setupStatusItem()

        overlayWindow = OverlayWindow()

        selectionMonitor = SelectionMonitor()
        selectionMonitor.onSelectionChanged = { [weak self] text in
            guard let self = self, self.isEnabled else { return }
            DispatchQueue.main.async {
                if let text = text, LatexDetector.containsLatex(text) {
                    let (latex, displayMode) = LatexDetector.extractLatex(text)
                    self.overlayWindow.renderLatex(latex, displayMode: displayMode)
                } else {
                    self.overlayWindow.hideOverlay()
                }
            }
        }
        selectionMonitor.start()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "\u{03A3}"  // Sigma symbol
            button.font = NSFont.systemFont(ofSize: 16)
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = .on
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        isEnabled.toggle()
        sender.state = isEnabled ? .on : .off
        if !isEnabled {
            overlayWindow.hideOverlay()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
