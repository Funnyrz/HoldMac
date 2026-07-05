import AppKit

final class BucketWindowController: NSWindowController {
    private let settings: AppSettings
    private let bucketView: BucketView
    private let store = BucketStore()
    private var hideWorkItem: DispatchWorkItem?
    private var listWindowController: BucketListWindowController?
    private var pinned = false

    init(settings: AppSettings) {
        self.settings = settings
        bucketView = BucketView(settings: settings, store: store)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 148),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = bucketView

        super.init(window: panel)

        bucketView.onDragEntered = { [weak self] in
            self?.cancelScheduledHide()
        }
        bucketView.onDragExited = { [weak self] in
            self?.scheduleHideIfNeeded(after: 1.2)
        }
        bucketView.onDropAccepted = { [weak self] in
            self?.scheduleHideIfNeeded(after: 2.0)
        }
        bucketView.onCloseRequested = { [weak self] in
            self?.hide()
        }
        bucketView.onListRequested = { [weak self] in
            self?.showList()
        }
        store.onChange = { [weak self] in
            self?.bucketView.needsDisplay = true
            self?.listWindowController?.refreshLanguage()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showForIncomingDrag(at screenPoint: NSPoint) {
        pinned = false
        show(on: screenForIncomingDrag(at: screenPoint))
        scheduleHideIfNeeded(after: autoHideDelayForCurrentShow())
    }

    func showPinned() {
        pinned = true
        show(on: preferredManualScreen())
    }

    func togglePinned() {
        if window?.isVisible == true {
            hide()
        } else {
            showPinned()
        }
    }

    func clear() {
        store.clear()
    }

    func refreshLanguage() {
        bucketView.needsDisplay = true
        listWindowController?.refreshLanguage()
    }

    func hide() {
        cancelScheduledHide()
        pinned = false
        listWindowController?.close()
        window?.orderOut(nil)
    }

    private func showList() {
        guard store.items.isEmpty == false else { return }
        cancelScheduledHide()

        if listWindowController == nil {
            listWindowController = BucketListWindowController(store: store, settings: settings) { [weak self] in
                self?.listWindowController = nil
                self?.scheduleHideIfNeeded(after: self?.settings.autoHideDelay ?? 5.0)
            }
        }
        listWindowController?.show(relativeTo: window)
    }

    private func show(on screen: NSScreen?) {
        guard let window else { return }
        positionWindow(window, on: screen)
        window.orderFrontRegardless()
    }

    private func autoHideDelayForCurrentShow() -> TimeInterval {
        settings.autoHideDelay
    }

    private func positionWindow(_ window: NSWindow, on screen: NSScreen?) {
        guard let screen = screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        let x = visibleFrame.midX - size.width / 2
        let y = visibleFrame.maxY - size.height - 12
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func screenForIncomingDrag(at point: NSPoint) -> NSScreen? {
        switch settings.screenPlacement {
        case .currentDragScreen:
            return screenContaining(point)
        case .mainScreen:
            return NSScreen.main ?? NSScreen.screens.first
        }
    }

    private func preferredManualScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }

    private func scheduleHideIfNeeded(after delay: TimeInterval) {
        guard !pinned else { return }
        guard listWindowController == nil else { return }
        cancelScheduledHide()

        let item = DispatchWorkItem { [weak self] in
            guard self?.bucketView.isMouseInside == false else { return }
            self?.window?.orderOut(nil)
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelScheduledHide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }
}
