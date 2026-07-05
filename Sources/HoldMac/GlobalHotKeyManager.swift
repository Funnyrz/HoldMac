import AppKit
import Carbon

final class GlobalHotKeyManager {
    private static let hotKeyID = EventHotKeyID(signature: fourCharCode("Bckt"), id: 1)

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let onPressed: @MainActor () -> Void

    init(onPressed: @escaping @MainActor () -> Void) {
        self.onPressed = onPressed
        installEventHandler()
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func update(shortcut: AppSettings.ShowBucketShortcut?) {
        unregister()
        guard let shortcut, shortcut.hasRequiredModifier else { return }

        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            Self.hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )

        if status == noErr {
            hotKeyRef = newHotKeyRef
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let callback: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return noErr }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr,
                  hotKeyID.signature == GlobalHotKeyManager.hotKeyID.signature,
                  hotKeyID.id == GlobalHotKeyManager.hotKeyID.id else {
                return noErr
            }

            let managerAddress = UInt(bitPattern: userData)
            Task { @MainActor in
                let managerPointer = UnsafeMutableRawPointer(bitPattern: managerAddress)!
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(managerPointer).takeUnretainedValue()
                manager.onPressed()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
    }

    private static func fourCharCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}
