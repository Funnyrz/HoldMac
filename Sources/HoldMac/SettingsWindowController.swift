import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    private let settingsView: SettingsView
    var onShortcutChanged: (() -> Void)? {
        get { settingsView.onShortcutChanged }
        set { settingsView.onShortcutChanged = newValue }
    }

    init(settings: AppSettings, onClearBucket: @escaping () -> Void) {
        let contentView = SettingsView(settings: settings, onClearBucket: onClearBucket)
        settingsView = contentView
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.verticalScrollElasticity = .allowed
        contentView.frame = NSRect(x: 0, y: 0, width: 600, height: 640)
        contentView.autoresizingMask = [.width]
        scrollView.documentView = contentView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        window.isReleasedWhenClosed = false

        super.init(window: window)
        refreshLanguage()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        refreshLanguage()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refreshLanguage() {
        window?.title = settingsView.localizedTitle
        settingsView.refreshLanguage()
    }
}

@MainActor
final class SettingsView: NSView {
    private let settings: AppSettings
    private let onClearBucket: () -> Void
    var onShortcutChanged: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let languageControl = NSSegmentedControl(labels: ["English", "中文"], trackingMode: .selectOne, target: nil, action: nil)
    private let triggerModeControl = NSSegmentedControl(labels: ["Drag", "Shake"], trackingMode: .selectOne, target: nil, action: nil)
    private let shakeAmplitudeSlider = NSSlider(value: 72, minValue: 40, maxValue: 140, target: nil, action: nil)
    private let shakeAmplitudeValueLabel = NSTextField(labelWithString: "")
    private let shortcutValueLabel = NSTextField(labelWithString: "")
    private let shortcutRecordButton = NSButton(title: "", target: nil, action: nil)
    private let shortcutClearButton = NSButton(title: "", target: nil, action: nil)
    private let operationControl = NSSegmentedControl(labels: ["Copy", "Move"], trackingMode: .selectOne, target: nil, action: nil)
    private let autoHideSlider = NSSlider(value: 5, minValue: 2, maxValue: 10, target: nil, action: nil)
    private let autoHideValueLabel = NSTextField(labelWithString: "")
    private let thresholdSlider = NSSlider(value: 10, minValue: 4, maxValue: 30, target: nil, action: nil)
    private let thresholdValueLabel = NSTextField(labelWithString: "")
    private let screenControl = NSSegmentedControl(labels: ["Current Screen", "Main Screen"], trackingMode: .selectOne, target: nil, action: nil)
    private let clearButton = NSButton(title: "", target: nil, action: nil)
    private let noteLabel = NSTextField(labelWithString: "")
    private let contentStack = NSStackView()
    private var shortcutMonitor: Any?
    private var isRecordingShortcut = false
    private var localizedRows: [(titleLabel: NSTextField, detailLabel: NSTextField, titleKey: Localizer.Key, detailKey: Localizer.Key)] = []

    var localizedTitle: String {
        settings.localizer.text(.settingsTitle)
    }

    init(settings: AppSettings, onClearBucket: @escaping () -> Void) {
        self.settings = settings
        self.onClearBucket = onClearBucket
        super.init(frame: NSRect(x: 0, y: 0, width: 600, height: 640))
        buildUI()
        syncFromSettings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor

        languageControl.target = self
        languageControl.action = #selector(languageChanged)

        triggerModeControl.target = self
        triggerModeControl.action = #selector(triggerModeChanged)

        shakeAmplitudeSlider.target = self
        shakeAmplitudeSlider.action = #selector(shakeAmplitudeChanged)
        shakeAmplitudeSlider.numberOfTickMarks = 6
        shakeAmplitudeSlider.allowsTickMarkValuesOnly = false

        shortcutValueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        shortcutValueLabel.alignment = .right
        shortcutRecordButton.target = self
        shortcutRecordButton.action = #selector(recordShortcut)
        shortcutRecordButton.bezelStyle = .rounded
        shortcutClearButton.target = self
        shortcutClearButton.action = #selector(clearShortcut)
        shortcutClearButton.bezelStyle = .rounded

        operationControl.target = self
        operationControl.action = #selector(defaultOperationChanged)

        autoHideSlider.target = self
        autoHideSlider.action = #selector(autoHideChanged)
        autoHideSlider.numberOfTickMarks = 9
        autoHideSlider.allowsTickMarkValuesOnly = false

        thresholdSlider.target = self
        thresholdSlider.action = #selector(thresholdChanged)
        thresholdSlider.numberOfTickMarks = 7
        thresholdSlider.allowsTickMarkValuesOnly = false

        screenControl.target = self
        screenControl.action = #selector(screenPlacementChanged)

        clearButton.target = self
        clearButton.action = #selector(clearBucket)
        clearButton.bezelStyle = .rounded

        noteLabel.font = .systemFont(ofSize: 12)
        noteLabel.textColor = .secondaryLabelColor
        noteLabel.lineBreakMode = .byWordWrapping

        contentStack.setViews([
            titleLabel,
            subtitleLabel,
            divider(),
            settingRow(titleKey: .language, detailKey: .languageDetail, control: languageControl),
            settingRow(titleKey: .triggerMode, detailKey: .triggerModeDetail, control: triggerModeControl),
            settingRow(titleKey: .shakeAmplitude, detailKey: .shakeAmplitudeDetail, control: pairedControl(shakeAmplitudeSlider, shakeAmplitudeValueLabel)),
            settingRow(titleKey: .showBucketShortcut, detailKey: .showBucketShortcutDetail, control: shortcutControl()),
            settingRow(titleKey: .defaultDragOut, detailKey: .defaultDragOutDetail, control: operationControl),
            settingRow(titleKey: .autoHide, detailKey: .autoHideDetail, control: pairedControl(autoHideSlider, autoHideValueLabel)),
            settingRow(titleKey: .triggerSensitivity, detailKey: .triggerSensitivityDetail, control: pairedControl(thresholdSlider, thresholdValueLabel)),
            settingRow(titleKey: .display, detailKey: .displayDetail, control: screenControl),
            divider(),
            settingRow(titleKey: .bucketContents, detailKey: .bucketContentsDetail, control: clearButton),
            noteLabel
        ], in: .top)
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            languageControl.widthAnchor.constraint(equalToConstant: 170),
            triggerModeControl.widthAnchor.constraint(equalToConstant: 170),
            operationControl.widthAnchor.constraint(equalToConstant: 170),
            screenControl.widthAnchor.constraint(equalToConstant: 220),
            noteLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }

    private func settingRow(titleKey: Localizer.Key, detailKey: Localizer.Key, control: NSView) -> NSView {
        let titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let detailLabel = NSTextField(labelWithString: "")
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byWordWrapping
        localizedRows.append((titleLabel, detailLabel, titleKey, detailKey))

        let labelStack = NSStackView(views: [titleLabel, detailLabel])
        labelStack.orientation = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 3

        let row = NSStackView(views: [labelStack, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 24
        row.translatesAutoresizingMaskIntoConstraints = false

        labelStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            row.widthAnchor.constraint(equalToConstant: 544),
            labelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 190)
        ])

        return row
    }

    private func pairedControl(_ slider: NSSlider, _ label: NSTextField) -> NSView {
        label.alignment = .right
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)

        let stack = NSStackView(views: [slider, label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8

        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(equalToConstant: 170),
            label.widthAnchor.constraint(equalToConstant: 48)
        ])

        return stack
    }

    private func divider() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 544)
        ])
        return box
    }

    private func syncFromSettings() {
        languageControl.selectedSegment = settings.appLanguage == .english ? 0 : 1
        triggerModeControl.selectedSegment = settings.triggerMode == .drag ? 0 : 1
        shakeAmplitudeSlider.doubleValue = Double(settings.shakeAmplitude)
        operationControl.selectedSegment = settings.defaultDragOperation == .copy ? 0 : 1
        autoHideSlider.doubleValue = settings.autoHideDelay
        thresholdSlider.doubleValue = Double(settings.dragTriggerThreshold)
        screenControl.selectedSegment = settings.screenPlacement == .currentDragScreen ? 0 : 1
        updateValueLabels()
        refreshLanguage()
    }

    func refreshLanguage() {
        let l10n = settings.localizer
        titleLabel.stringValue = l10n.text(.settingsTitle)
        subtitleLabel.stringValue = l10n.text(.settingsSubtitle)
        languageControl.setLabel(l10n.text(.languageEnglish), forSegment: 0)
        languageControl.setLabel(l10n.text(.languageChinese), forSegment: 1)
        triggerModeControl.setLabel(l10n.text(.triggerDrag), forSegment: 0)
        triggerModeControl.setLabel(l10n.text(.triggerShake), forSegment: 1)
        operationControl.setLabel(l10n.text(.copy), forSegment: 0)
        operationControl.setLabel(l10n.text(.move), forSegment: 1)
        screenControl.setLabel(l10n.text(.currentScreen), forSegment: 0)
        screenControl.setLabel(l10n.text(.mainScreen), forSegment: 1)
        shortcutRecordButton.title = isRecordingShortcut ? l10n.text(.shortcutRecording) : l10n.text(.shortcutRecord)
        shortcutClearButton.title = l10n.text(.shortcutClear)
        clearButton.title = l10n.text(.clearBucket)
        noteLabel.stringValue = l10n.text(.modifierNote)
        for row in localizedRows {
            row.titleLabel.stringValue = l10n.text(row.titleKey)
            row.detailLabel.stringValue = l10n.text(row.detailKey)
        }
        updateDocumentSize()
    }

    private func updateDocumentSize() {
        layoutSubtreeIfNeeded()
        let viewportSize = enclosingScrollView?.contentView.bounds.size ?? bounds.size
        let width = max(viewportSize.width, 600)
        let contentHeight = ceil(contentStack.fittingSize.height + 48)
        let height = max(viewportSize.height, contentHeight)
        setFrameSize(NSSize(width: width, height: height))
    }

    private func updateValueLabels() {
        autoHideValueLabel.stringValue = String(format: "%.1fs", settings.autoHideDelay)
        thresholdValueLabel.stringValue = String(format: "%.0fpt", settings.dragTriggerThreshold)
        shakeAmplitudeValueLabel.stringValue = String(format: "%.0fpt", settings.shakeAmplitude)
        shortcutValueLabel.stringValue = isRecordingShortcut
            ? settings.localizer.text(.shortcutRecording)
            : settings.shortcutDisplayString(settings.showBucketShortcut)
        let isShakeMode = settings.triggerMode == .shake
        shakeAmplitudeSlider.isEnabled = isShakeMode
        shakeAmplitudeValueLabel.textColor = isShakeMode ? .labelColor : .disabledControlTextColor
    }

    private func shortcutControl() -> NSView {
        let stack = NSStackView(views: [shortcutValueLabel, shortcutRecordButton, shortcutClearButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8

        NSLayoutConstraint.activate([
            shortcutValueLabel.widthAnchor.constraint(equalToConstant: 92),
            shortcutRecordButton.widthAnchor.constraint(equalToConstant: 84),
            shortcutClearButton.widthAnchor.constraint(equalToConstant: 68)
        ])

        return stack
    }

    @objc private func defaultOperationChanged() {
        settings.defaultDragOperation = operationControl.selectedSegment == 1 ? .move : .copy
    }

    @objc private func triggerModeChanged() {
        settings.triggerMode = triggerModeControl.selectedSegment == 1 ? .shake : .drag
        updateValueLabels()
    }

    @objc private func shakeAmplitudeChanged() {
        settings.shakeAmplitude = CGFloat(shakeAmplitudeSlider.doubleValue.rounded())
        shakeAmplitudeSlider.doubleValue = Double(settings.shakeAmplitude)
        updateValueLabels()
    }

    @objc private func recordShortcut() {
        startRecordingShortcut()
    }

    @objc private func clearShortcut() {
        stopRecordingShortcut()
        settings.showBucketShortcut = nil
        onShortcutChanged?()
        updateValueLabels()
    }

    @objc private func languageChanged() {
        settings.appLanguage = languageControl.selectedSegment == 1 ? .chinese : .english
        refreshLanguage()
        window?.title = localizedTitle
        NSApp.delegate.flatMap { $0 as? AppDelegate }?.rebuildStatusMenu()
    }

    @objc private func autoHideChanged() {
        settings.autoHideDelay = autoHideSlider.doubleValue
        updateValueLabels()
    }

    @objc private func thresholdChanged() {
        settings.dragTriggerThreshold = CGFloat(thresholdSlider.doubleValue.rounded())
        thresholdSlider.doubleValue = Double(settings.dragTriggerThreshold)
        updateValueLabels()
    }

    @objc private func screenPlacementChanged() {
        settings.screenPlacement = screenControl.selectedSegment == 1 ? .mainScreen : .currentDragScreen
    }

    @objc private func clearBucket() {
        onClearBucket()
    }

    private func startRecordingShortcut() {
        stopRecordingShortcut()
        isRecordingShortcut = true
        refreshLanguage()
        updateValueLabels()

        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleShortcutRecording(event)
            return nil
        }
    }

    private func stopRecordingShortcut() {
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
            self.shortcutMonitor = nil
        }
        isRecordingShortcut = false
        refreshLanguage()
    }

    private func handleShortcutRecording(_ event: NSEvent) {
        if event.keyCode == 53 {
            stopRecordingShortcut()
            updateValueLabels()
            return
        }

        if event.keyCode == 51 || event.keyCode == 117 {
            settings.showBucketShortcut = nil
            onShortcutChanged?()
            stopRecordingShortcut()
            updateValueLabels()
            return
        }

        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0, isRecordableKey(event.keyCode) else { return }

        settings.showBucketShortcut = AppSettings.ShowBucketShortcut(keyCode: UInt32(event.keyCode), carbonModifiers: modifiers)
        onShortcutChanged?()
        stopRecordingShortcut()
        updateValueLabels()
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= ShortcutModifier.command }
        if flags.contains(.option) { modifiers |= ShortcutModifier.option }
        if flags.contains(.control) { modifiers |= ShortcutModifier.control }
        if flags.contains(.shift) { modifiers |= ShortcutModifier.shift }
        return modifiers
    }

    private func isRecordableKey(_ keyCode: UInt16) -> Bool {
        ![53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(keyCode)
    }
}
