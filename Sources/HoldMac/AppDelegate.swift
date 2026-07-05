import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private var statusItem: NSStatusItem?
    private var bucketController: BucketWindowController?
    private var dragWatcher: DragWatcher?
    private var settingsController: SettingsWindowController?
    private var hotKeyManager: GlobalHotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = BucketWindowController(settings: settings)
        bucketController = controller
        dragWatcher = DragWatcher(settings: settings) { [weak controller] screenPoint in
            controller?.showForIncomingDrag(at: screenPoint)
        }
        settingsController = SettingsWindowController(settings: settings) { [weak controller] in
            controller?.clear()
        }
        settingsController?.onShortcutChanged = { [weak self] in
            self?.refreshGlobalHotKey()
        }
        hotKeyManager = GlobalHotKeyManager { [weak controller] in
            controller?.togglePinned()
        }
        refreshGlobalHotKey()

        installStatusItem()
        showSettingsOnLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragWatcher?.stop()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "archivebox", accessibilityDescription: "文件中转桶")
        item.button?.imagePosition = .imageOnly
        statusItem = item
        rebuildStatusMenu()
    }

    func rebuildStatusMenu() {
        guard let item = statusItem else { return }
        let l10n = settings.localizer
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: l10n.text(.settingsMenu), action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: l10n.text(.showBucket), action: #selector(showBucket), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: l10n.text(.clearBucket), action: #selector(clearBucket), keyEquivalent: "k"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: l10n.text(.quitBucket), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        bucketController?.refreshLanguage()
    }

    @objc private func showBucket() {
        bucketController?.showPinned()
    }

    @objc private func clearBucket() {
        bucketController?.clear()
    }

    @objc private func showSettings() {
        settingsController?.show()
    }

    private func refreshGlobalHotKey() {
        hotKeyManager?.update(shortcut: settings.showBucketShortcut)
    }

    private func showSettingsOnLaunch() {
        Task { @MainActor in
            await Task.yield()
            settingsController?.show()
        }
    }
}
