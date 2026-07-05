import AppKit

final class DragWatcher {
    private let settings: AppSettings
    private let onLikelyFileDrag: @MainActor (NSPoint) -> Void
    private var mouseDownPoint: NSPoint?
    private var mouseDownAppBundleID: String?
    private var didTriggerForCurrentDrag = false
    private var shakeRecognizer = ShakeDragRecognizer()
    private var monitors: [Any] = []

    init(settings: AppSettings, onLikelyFileDrag: @escaping @MainActor (NSPoint) -> Void) {
        self.settings = settings
        self.onLikelyFileDrag = onLikelyFileDrag
        start()
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

    private func start() {
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.mouseDownPoint = event.locationInWindow
            self?.mouseDownAppBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            self?.didTriggerForCurrentDrag = false
            self?.shakeRecognizer.reset()
        } as Any)

        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
        } as Any)

        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.mouseDownPoint = nil
            self?.mouseDownAppBundleID = nil
            self?.didTriggerForCurrentDrag = false
            self?.shakeRecognizer.reset()
        } as Any)
    }

    private func handleMouseDragged(_ event: NSEvent) {
        guard !didTriggerForCurrentDrag else { return }
        guard mouseDownAppBundleID == "com.apple.finder" else { return }
        guard let start = mouseDownPoint else { return }

        let distance = hypot(event.locationInWindow.x - start.x, event.locationInWindow.y - start.y)
        guard distance > settings.dragTriggerThreshold else { return }

        switch settings.triggerMode {
        case .drag:
            trigger(at: event.locationInWindow)
        case .shake:
            guard dragPasteboardContainsFileURL() else { return }
            guard shakeRecognizer.update(
                with: event.locationInWindow,
                from: start,
                dragTriggerThreshold: settings.dragTriggerThreshold,
                shakeAmplitude: settings.shakeAmplitude
            ) else { return }
            trigger(at: event.locationInWindow)
        }
    }

    private func dragPasteboardContainsFileURL() -> Bool {
        let pasteboard = NSPasteboard(name: .drag)
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: options) {
            return true
        }

        guard let types = pasteboard.types else { return false }
        return types.contains(.fileURL) || types.contains(NSPasteboard.PasteboardType("NSFilenamesPboardType"))
    }

    private func trigger(at screenPoint: NSPoint) {
        didTriggerForCurrentDrag = true
        Task { @MainActor [onLikelyFileDrag, screenPoint] in
            onLikelyFileDrag(screenPoint)
        }
    }
}

struct ShakeDragRecognizer {
    private enum Axis {
        case horizontal
        case vertical
    }

    private var isPrimed = false
    private var lastPoint: NSPoint?
    private var axis: Axis?
    private var lastDirection: CGFloat = 0
    private var reversalCount = 0
    private var accumulatedDistance: CGFloat = 0

    mutating func reset() {
        isPrimed = false
        lastPoint = nil
        axis = nil
        lastDirection = 0
        reversalCount = 0
        accumulatedDistance = 0
    }

    mutating func update(
        with point: NSPoint,
        from start: NSPoint,
        dragTriggerThreshold: CGFloat,
        shakeAmplitude: CGFloat
    ) -> Bool {
        guard isPrimed else {
            if hypot(point.x - start.x, point.y - start.y) >= max(dragTriggerThreshold * 3, shakeAmplitude * 0.5) {
                isPrimed = true
                lastPoint = point
            }
            return false
        }

        guard let previousPoint = lastPoint else {
            lastPoint = point
            return false
        }

        let dx = point.x - previousPoint.x
        let dy = point.y - previousPoint.y
        let currentAxis: Axis = abs(dx) >= abs(dy) ? .horizontal : .vertical
        let delta = currentAxis == .horizontal ? dx : dy
        let movement = abs(delta)

        lastPoint = point
        let minimumStep = max(CGFloat(8), shakeAmplitude * 0.12)
        guard movement >= minimumStep else { return false }

        let direction: CGFloat = delta > 0 ? 1 : -1
        if axis == currentAxis, lastDirection != 0, lastDirection != direction {
            reversalCount += 1
        }

        axis = currentAxis
        lastDirection = direction
        accumulatedDistance += movement

        return reversalCount >= 3 && accumulatedDistance >= shakeAmplitude
    }
}
