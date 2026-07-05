import AppKit

@MainActor
final class BucketListWindowController: NSWindowController, NSWindowDelegate {
    private let listView: BucketListView
    private let onClosed: () -> Void

    init(store: BucketStore, settings: AppSettings, onClosed: @escaping () -> Void) {
        self.onClosed = onClosed
        listView = BucketListView(store: store, settings: settings)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = settings.localizer.text(.bucketListTitle)
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = listView
        panel.isReleasedWhenClosed = false

        super.init(window: panel)
        panel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(relativeTo bucketWindow: NSWindow?) {
        guard let window else { return }
        positionWindow(window, relativeTo: bucketWindow)
        listView.reload()
        window.title = listView.localizedTitle
        window.orderFrontRegardless()
    }

    func refreshLanguage() {
        window?.title = listView.localizedTitle
        listView.reload()
    }

    func windowWillClose(_ notification: Notification) {
        onClosed()
    }

    private func positionWindow(_ window: NSWindow, relativeTo bucketWindow: NSWindow?) {
        let screen = bucketWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        let bucketFrame = bucketWindow?.frame ?? .zero
        let x = min(max(bucketFrame.midX - size.width / 2, visibleFrame.minX + 12), visibleFrame.maxX - size.width - 12)
        let proposedY = bucketFrame.minY - size.height - 10
        let y = proposedY >= visibleFrame.minY + 12
            ? proposedY
            : visibleFrame.maxY - size.height - 64
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

@MainActor
final class BucketListView: NSView {
    private let store: BucketStore
    private let settings: AppSettings
    private let headerLabel = NSTextField(labelWithString: "")
    private let emptyLabel = NSTextField(labelWithString: "")
    private let scrollView = NSScrollView()
    private let stackView = NSStackView()

    var localizedTitle: String {
        settings.localizer.text(.bucketListTitle)
    }

    init(store: BucketStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        super.init(frame: NSRect(x: 0, y: 0, width: 520, height: 420))
        buildUI()
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        let l10n = settings.localizer
        let itemText = l10n.text(store.items.count == 1 ? .itemSingular : .itemPlural)
        headerLabel.stringValue = "\(store.items.count) \(itemText)"
        emptyLabel.stringValue = l10n.text(.bucketListEmpty)

        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for item in store.items {
            stackView.addArrangedSubview(BucketListRowView(item: item, store: store, settings: settings))
        }

        emptyLabel.isHidden = store.items.isEmpty == false
    }

    private func buildUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        headerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stackView)
        scrollView.documentView = documentView

        emptyLabel.font = .systemFont(ofSize: 13)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: documentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
    }
}

@MainActor
final class BucketListRowView: NSView {
    private let item: BucketItem
    private let store: BucketStore
    private let settings: AppSettings
    private var isMouseDownOnRemove = false
    private var didStartDrag = false
    private var pendingDragOperationOverride: NSDragOperation?
    private var pendingDragUsedOptionCopy = false

    init(item: BucketItem, store: BucketStore, settings: AppSettings) {
        self.item = item
        self.store = store
        self.settings = settings
        super.init(frame: NSRect(x: 0, y: 0, width: 496, height: 56))
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 480).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.separatorColor.withAlphaComponent(0.45).setStroke()
        let separator = NSBezierPath()
        separator.move(to: NSPoint(x: 12, y: bounds.maxY - 0.5))
        separator.line(to: NSPoint(x: bounds.maxX - 12, y: bounds.maxY - 0.5))
        separator.stroke()

        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 32, height: 32)
        icon.draw(in: NSRect(x: 14, y: 12, width: 32, height: 32))

        drawText(item.displayName, in: NSRect(x: 58, y: 9, width: bounds.width - 150, height: 18), font: .systemFont(ofSize: 13, weight: .medium), color: .labelColor, lineBreak: .byTruncatingMiddle)
        drawText(pathDisplayString(), in: NSRect(x: 58, y: 29, width: bounds.width - 150, height: 16), font: .systemFont(ofSize: 11), color: .secondaryLabelColor, lineBreak: .byTruncatingMiddle)

        drawRemoveButton()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        isMouseDownOnRemove = removeButtonRect.contains(point)
        didStartDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isMouseDownOnRemove, !didStartDrag else { return }
        didStartDrag = true

        pendingDragUsedOptionCopy = event.modifierFlags.contains(.option)
        pendingDragOperationOverride = pendingDragUsedOptionCopy ? .copy : nil

        let draggingItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
        draggingItem.setDraggingFrame(NSRect(x: 0, y: 0, width: 160, height: 56), contents: dragImage())
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isMouseDownOnRemove, removeButtonRect.contains(point) {
            store.remove(item)
        }
        isMouseDownOnRemove = false
    }

    private var removeButtonRect: NSRect {
        NSRect(x: bounds.maxX - 82, y: 16, width: 64, height: 24)
    }

    private func drawRemoveButton() {
        let rect = removeButtonRect
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
        NSColor.separatorColor.setStroke()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).stroke()

        drawText(
            settings.localizer.text(.removeItem),
            in: NSRect(x: rect.minX + 6, y: rect.minY + 4, width: rect.width - 12, height: 16),
            font: .systemFont(ofSize: 11, weight: .medium),
            color: .labelColor,
            lineBreak: .byTruncatingTail,
            alignment: .center
        )
    }

    private func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, lineBreak: NSLineBreakMode, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = lineBreak
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }

    private func pathDisplayString() -> String {
        let parent = item.url.deletingLastPathComponent().path
        return parent.isEmpty ? settings.localizer.text(.pathUnavailable) : parent
    }

    private func dragImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 160, height: 56))
        image.lockFocus()
        NSColor(calibratedWhite: 0.08, alpha: 0.86).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 160, height: 56), xRadius: 10, yRadius: 10).fill()

        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 28, height: 28)
        icon.draw(in: NSRect(x: 12, y: 14, width: 28, height: 28))
        drawText(item.displayName, in: NSRect(x: 48, y: 19, width: 100, height: 18), font: .systemFont(ofSize: 12, weight: .medium), color: .white, lineBreak: .byTruncatingMiddle)

        image.unlockFocus()
        return image
    }
}

extension BucketListRowView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        guard context == .outsideApplication else { return [] }
        return DragOperationPrompt.operationMask(settings: settings, override: pendingDragOperationOverride)
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        !settings.allowModifierOverride
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation == .move {
            store.remove(item)
        } else if operation == .copy, pendingDragUsedOptionCopy {
            let selectedOperation = DragOperationPrompt.selectedPostCopyOperation(settings: settings)
            if selectedOperation == .move {
                let movedURLs = DragOperationPrompt.moveOriginalsToTrash([item.url], settings: settings)
                if movedURLs.contains(item.url) {
                    store.remove(item)
                }
            }
        }
        pendingDragOperationOverride = nil
        pendingDragUsedOptionCopy = false
    }
}
