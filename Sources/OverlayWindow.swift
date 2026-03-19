import Cocoa
import WebKit

class OverlayWindow: NSPanel {
    private var webView: WKWebView!
    private var isWebViewReady = false
    private var pendingRender: (latex: String, displayMode: Bool)?
    private var pendingMixedRender: String?

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 150),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.hidesOnDeactivate = false

        setupWebView()
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(LeakAvoider(self), name: "sizeHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: self.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        self.contentView?.addSubview(webView)

        if let resourceURL = Bundle.main.resourceURL {
            let htmlURL = resourceURL.appendingPathComponent("render.html")
            webView.loadFileURL(htmlURL, allowingReadAccessTo: resourceURL)
        }
    }

    func renderLatex(_ latex: String, displayMode: Bool = true) {
        guard isWebViewReady else {
            pendingRender = (latex, displayMode)
            return
        }

        let escaped = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let js = "renderLatex('\(escaped)', \(displayMode))"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("JS error: \(error.localizedDescription)")
            }
        }

        positionNearMouse()

        if !self.isVisible {
            self.alphaValue = 0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                self.animator().alphaValue = 1
            }
        }
    }

    func renderMixedContent(_ text: String) {
        guard isWebViewReady else {
            pendingRender = nil
            pendingMixedRender = text
            return
        }

        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        let js = "renderMixed('\(escaped)')"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("JS error: \(error.localizedDescription)")
            }
        }

        positionNearMouse()

        if !self.isVisible {
            self.alphaValue = 0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                self.animator().alphaValue = 1
            }
        }
    }

    func hideOverlay() {
        guard self.isVisible else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }

    private func positionNearMouse() {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main else { return }

        let sf = screen.visibleFrame
        let ws = self.frame.size

        var x = mouse.x + 20
        var y = mouse.y + 30

        if x + ws.width > sf.maxX { x = mouse.x - ws.width - 20 }
        if y + ws.height > sf.maxY { y = mouse.y - ws.height - 30 }
        if x < sf.minX { x = sf.minX }
        if y < sf.minY { y = sf.minY }

        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func handleSizeMessage(_ body: Any) {
        guard let jsonString = body as? String,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: CGFloat],
              let width = dict["width"],
              let height = dict["height"] else { return }

        let newWidth = max(100, min(width, 800))
        let newHeight = max(50, min(height, 800))

        let origin = self.frame.origin
        self.setFrame(NSRect(x: origin.x, y: origin.y, width: newWidth, height: newHeight), display: true)
    }
}

// MARK: - WKNavigationDelegate
extension OverlayWindow: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isWebViewReady = true
        if let text = pendingMixedRender {
            pendingMixedRender = nil
            pendingRender = nil
            renderMixedContent(text)
        } else if let pending = pendingRender {
            pendingRender = nil
            renderLatex(pending.latex, displayMode: pending.displayMode)
        }
    }
}

// MARK: - WKScriptMessageHandler
extension OverlayWindow: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sizeHandler" {
            handleSizeMessage(message.body)
        }
    }
}

/// Weak wrapper to avoid retain cycle with WKUserContentController
class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
