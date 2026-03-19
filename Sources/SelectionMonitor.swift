import Cocoa

class SelectionMonitor {
    var onSelectionChanged: ((String?) -> Void)?

    private var timer: Timer?
    private var lastSelection: String?
    private var debounceTimer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkSelection()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
    }

    private func checkSelection() {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success else {
            updateSelection(nil)
            return
        }

        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedApp as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
            updateSelection(nil)
            return
        }

        var selectedText: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
              let text = selectedText as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            updateSelection(nil)
            return
        }

        updateSelection(text)
    }

    private func updateSelection(_ text: String?) {
        guard text != lastSelection else { return }
        lastSelection = text

        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.onSelectionChanged?(text)
        }
    }
}
