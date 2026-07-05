import AppKit
import UniformTypeIdentifiers

final class BucketView: NSView {
    var onDragEntered: (() -> Void)?
    var onDragExited: (() -> Void)?
    var onDropAccepted: (() -> Void)?
    var onCloseRequested: (() -> Void)?
    var onListRequested: (() -> Void)?

    private let settings: AppSettings
    private let store: BucketStore
    private var isDropTargeted = false
    private var isCloseHovered = false
    private var isClearHovered = false
    private var trackingArea: NSTrackingArea?
    private var draggedURLs: Set<URL> = []
    private var pendingDragOperationOverride: NSDragOperation?
    private var pendingDragUsedOptionCopy = false
    private var dragStartAllowsOutgoing = false
    private var mouseDownPoint: NSPoint?

    var isMouseInside = false

    private var items: [BucketItem] {
        store.items
    }

    init(settings: AppSettings, store: BucketStore) {
        self.settings = settings
        self.store = store
        super.init(frame: .zero)
        wantsLayer = true
        registerForDraggedTypes([.fileURL])
    }

    override init(frame frameRect: NSRect) {
        settings = AppSettings()
        store = BucketStore()
        super.init(frame: frameRect)
        wantsLayer = true
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isMouseInside = true
        updateCloseHover(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        isMouseInside = false
        if isCloseHovered || isClearHovered {
            isCloseHovered = false
            isClearHovered = false
            needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        updateCloseHover(with: event)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard readFileURLs(from: sender.draggingPasteboard).isEmpty == false else {
            return []
        }
        isDropTargeted = true
        needsDisplay = true
        onDragEntered?()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDropTargeted = false
        needsDisplay = true
        onDragExited?()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return readFileURLs(from: sender.draggingPasteboard).isEmpty == false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = readFileURLs(from: sender.draggingPasteboard)
        guard urls.isEmpty == false else { return false }

        append(urls)
        isDropTargeted = false
        onDropAccepted?()
        return true
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDropTargeted = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStartAllowsOutgoing = false
        mouseDownPoint = point
        if closeButtonRect.contains(point) {
            onCloseRequested?()
            return
        }
        if clearButtonRect.contains(point) {
            clear()
            return
        }
        dragStartAllowsOutgoing = contentDragRect.contains(point) || item(at: point) != nil
    }

    override func mouseDragged(with event: NSEvent) {
        guard items.isEmpty == false, dragStartAllowsOutgoing else { return }
        if let mouseDownPoint {
            let point = convert(event.locationInWindow, from: nil)
            guard hypot(point.x - mouseDownPoint.x, point.y - mouseDownPoint.y) >= 4 else { return }
        }

        let outgoingItems = items
        pendingDragUsedOptionCopy = event.modifierFlags.contains(.option)
        pendingDragOperationOverride = pendingDragUsedOptionCopy ? .copy : nil
        draggedURLs = Set(outgoingItems.map(\.url))

        let draggingItems = items.map { item in
            let draggingItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
            draggingItem.setDraggingFrame(bounds.insetBy(dx: 112, dy: 34), contents: dragImage())
            return draggingItem
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
        dragStartAllowsOutgoing = false
        mouseDownPoint = nil
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            dragStartAllowsOutgoing = false
            mouseDownPoint = nil
        }
        guard items.isEmpty == false, dragStartAllowsOutgoing else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard contentDragRect.contains(point) || item(at: point) != nil else { return }
        onListRequested?()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawPanel()
        drawClearButton()
        drawCloseButton()
        drawBucket()
        drawItems()
    }

    func clear() {
        store.clear()
        draggedURLs.removeAll()
    }

    private func append(_ urls: [URL]) {
        store.append(urls)
    }

    private func readFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let classes: [AnyClass] = [NSURL.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]

        return pasteboard.readObjects(forClasses: classes, options: options) as? [URL] ?? []
    }

    private func item(at point: NSPoint) -> BucketItem? {
        itemRects().first { $0.rect.contains(point) }?.item
    }

    private func itemRects() -> [(item: BucketItem, rect: NSRect)] {
        guard usesIndividualItemLayout else { return [] }
        let maxVisible = min(items.count, 4)
        guard maxVisible > 0 else { return [] }

        let itemSize = NSSize(width: 54, height: 54)
        let gap: CGFloat = 10
        let totalWidth = CGFloat(maxVisible) * itemSize.width + CGFloat(maxVisible - 1) * gap
        let startX = bounds.midX - totalWidth / 2
        let y: CGFloat = 62

        return items.prefix(maxVisible).enumerated().map { index, item in
            let x = startX + CGFloat(index) * (itemSize.width + gap)
            return (item, NSRect(origin: NSPoint(x: x, y: y), size: itemSize))
        }
    }

    private var usesIndividualItemLayout: Bool {
        items.count <= 4
    }

    private var contentDragRect: NSRect {
        NSRect(x: 38, y: 58, width: bounds.width - 76, height: 58)
    }

    private func drawPanel() {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)

        let fill = isDropTargeted
            ? NSColor(calibratedRed: 0.16, green: 0.39, blue: 0.87, alpha: 0.9)
            : NSColor(calibratedWhite: 0.08, alpha: 0.88)
        fill.setFill()
        path.fill()

        NSColor(calibratedWhite: 1, alpha: isDropTargeted ? 0.42 : 0.16).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private var closeButtonRect: NSRect {
        NSRect(x: bounds.maxX - 40, y: bounds.maxY - 40, width: 24, height: 24)
    }

    private var clearButtonRect: NSRect {
        let text = settings.localizer.text(.clearBucketInline)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium)
        ]
        let width = max(CGFloat(44), ceil(text.size(withAttributes: attributes).width) + 20)
        return NSRect(x: closeButtonRect.minX - width - 8, y: bounds.maxY - 40, width: width, height: 24)
    }

    private func updateCloseHover(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let closeHovered = closeButtonRect.contains(point)
        let clearHovered = clearButtonRect.contains(point)
        guard closeHovered != isCloseHovered || clearHovered != isClearHovered else { return }
        isCloseHovered = closeHovered
        isClearHovered = clearHovered
        needsDisplay = true
    }

    private func drawClearButton() {
        let rect = clearButtonRect
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        let fill = isClearHovered
            ? NSColor(calibratedWhite: 1, alpha: 0.24)
            : NSColor(calibratedWhite: 1, alpha: 0.12)
        fill.setFill()
        path.fill()

        let text = settings.localizer.text(.clearBucketInline)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 1, alpha: isClearHovered ? 0.92 : 0.72),
            .paragraphStyle: paragraph
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            in: NSRect(x: rect.minX + 6, y: rect.midY - size.height / 2, width: rect.width - 12, height: size.height),
            withAttributes: attributes
        )
    }

    private func drawCloseButton() {
        let rect = closeButtonRect
        let circle = NSBezierPath(ovalIn: rect)
        let fill = isCloseHovered
            ? NSColor(calibratedWhite: 1, alpha: 0.24)
            : NSColor(calibratedWhite: 1, alpha: 0.12)
        fill.setFill()
        circle.fill()

        NSColor(calibratedWhite: 1, alpha: isCloseHovered ? 0.92 : 0.68).setStroke()
        let insetRect = rect.insetBy(dx: 7, dy: 7)
        let path = NSBezierPath()
        path.lineWidth = 1.6
        path.lineCapStyle = .round
        path.move(to: NSPoint(x: insetRect.minX, y: insetRect.minY))
        path.line(to: NSPoint(x: insetRect.maxX, y: insetRect.maxY))
        path.move(to: NSPoint(x: insetRect.maxX, y: insetRect.minY))
        path.line(to: NSPoint(x: insetRect.minX, y: insetRect.maxY))
        path.stroke()
    }

    private func drawBucket() {
        let bucketRect = NSRect(x: bounds.midX - 33, y: 22, width: 66, height: 36)
        let lipRect = NSRect(x: bucketRect.minX - 8, y: bucketRect.maxY - 4, width: bucketRect.width + 16, height: 10)

        NSColor(calibratedWhite: 1, alpha: 0.92).setFill()
        NSBezierPath(roundedRect: lipRect, xRadius: 5, yRadius: 5).fill()

        let body = NSBezierPath()
        body.move(to: NSPoint(x: bucketRect.minX + 8, y: bucketRect.maxY))
        body.line(to: NSPoint(x: bucketRect.maxX - 8, y: bucketRect.maxY))
        body.line(to: NSPoint(x: bucketRect.maxX - 16, y: bucketRect.minY))
        body.line(to: NSPoint(x: bucketRect.minX + 16, y: bucketRect.minY))
        body.close()
        NSColor(calibratedRed: 0.92, green: 0.95, blue: 1, alpha: 0.94).setFill()
        body.fill()

        NSColor(calibratedWhite: 0, alpha: 0.2).setStroke()
        body.lineWidth = 1
        body.stroke()
    }

    private func drawItems() {
        if items.isEmpty {
            drawEmptyState()
            return
        }

        guard usesIndividualItemLayout else {
            drawOverflowSummary()
            return
        }

        for pair in itemRects() {
            drawItem(pair.item, in: pair.rect)
        }
    }

    private func drawEmptyState() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 1, alpha: 0.72)
        ]
        let text = settings.localizer.text(.dropFilesHere)
        let size = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: bounds.midX - size.width / 2, y: 82), withAttributes: attributes)
    }

    private func drawItem(_ item: BucketItem, in rect: NSRect) {
        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 32, height: 32)
        icon.draw(in: NSRect(x: rect.midX - 16, y: rect.maxY - 36, width: 32, height: 32))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingMiddle

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor(calibratedWhite: 1, alpha: 0.84),
            .paragraphStyle: paragraph
        ]
        item.displayName.draw(in: NSRect(x: rect.minX - 7, y: rect.minY, width: rect.width + 14, height: 18), withAttributes: attributes)
    }

    private func drawOverflowSummary() {
        let visibleIcons = min(items.count, 5)
        let iconSize = NSSize(width: 34, height: 34)
        let overlap: CGFloat = 17
        let totalIconWidth = iconSize.width + CGFloat(visibleIcons - 1) * overlap
        let iconStartX: CGFloat = 64
        let iconY: CGFloat = 76

        for (index, item) in items.prefix(visibleIcons).enumerated() {
            let x = iconStartX + CGFloat(index) * overlap
            let shadowRect = NSRect(x: x - 3, y: iconY - 3, width: iconSize.width + 6, height: iconSize.height + 6)
            NSColor(calibratedWhite: 0, alpha: 0.22).setFill()
            NSBezierPath(roundedRect: shadowRect, xRadius: 8, yRadius: 8).fill()

            NSColor(calibratedWhite: 1, alpha: 0.9).setFill()
            NSBezierPath(roundedRect: NSRect(x: x - 2, y: iconY - 2, width: iconSize.width + 4, height: iconSize.height + 4), xRadius: 7, yRadius: 7).fill()

            let icon = NSWorkspace.shared.icon(forFile: item.url.path)
            icon.size = iconSize
            icon.draw(in: NSRect(origin: NSPoint(x: x, y: iconY), size: iconSize))
        }

        let remaining = items.count - visibleIcons
        if remaining > 0 {
            drawBadge("+\(remaining)", at: NSPoint(x: iconStartX + totalIconWidth - 10, y: iconY - 4))
        }

        let textX = iconStartX + totalIconWidth + 20
        let textWidth = bounds.maxX - textX - 52
        let itemText = settings.localizer.text(items.count == 1 ? .itemSingular : .itemPlural)
        let title = "\(items.count) \(itemText)"
        drawSummaryText(
            title,
            in: NSRect(x: textX, y: 88, width: textWidth, height: 18),
            font: .systemFont(ofSize: 14, weight: .semibold),
            alpha: 0.94,
            lineBreakMode: .byTruncatingTail
        )

        let subtitle = overflowSubtitle()
        drawSummaryText(
            subtitle,
            in: NSRect(x: textX, y: 69, width: textWidth, height: 16),
            font: .systemFont(ofSize: 11, weight: .regular),
            alpha: 0.72,
            lineBreakMode: .byTruncatingMiddle
        )
    }

    private func overflowSubtitle() -> String {
        guard let firstItem = items.first else { return "" }
        switch settings.appLanguage {
        case .english:
            return "\(firstItem.displayName) +\(items.count - 1) more"
        case .chinese:
            return "\(firstItem.displayName) 等 \(items.count) 项"
        }
    }

    private func drawSummaryText(_ text: String, in rect: NSRect, font: NSFont, alpha: CGFloat, lineBreakMode: NSLineBreakMode) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = lineBreakMode
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedWhite: 1, alpha: alpha),
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }

    private func drawBadge(_ text: String, at point: NSPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1)
        ]
        let size = text.size(withAttributes: attributes)
        let rect = NSRect(x: point.x, y: point.y, width: size.width + 14, height: 22)
        NSColor(calibratedWhite: 1, alpha: 0.9).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11).fill()
        text.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
    }

    private func dragImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 136, height: 70))
        image.lockFocus()

        NSColor(calibratedWhite: 0.08, alpha: 0.84).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 136, height: 70), xRadius: 12, yRadius: 12).fill()

        let itemText = settings.localizer.text(items.count == 1 ? .itemSingular : .itemPlural)
        let text = "\(items.count) \(itemText)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: 68 - size.width / 2, y: 27), withAttributes: attributes)

        image.unlockFocus()
        return image
    }
}

extension BucketView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        guard context == .outsideApplication else { return [] }
        return DragOperationPrompt.operationMask(settings: settings, override: pendingDragOperationOverride)
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        !settings.allowModifierOverride
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation == .move {
            store.remove(urls: draggedURLs)
        } else if operation == .copy, pendingDragUsedOptionCopy {
            let selectedOperation = DragOperationPrompt.selectedPostCopyOperation(settings: settings)
            if selectedOperation == .move {
                let movedURLs = DragOperationPrompt.moveOriginalsToTrash(draggedURLs, settings: settings)
                store.remove(urls: movedURLs)
            }
        }
        draggedURLs.removeAll()
        pendingDragOperationOverride = nil
        pendingDragUsedOptionCopy = false
    }
}
