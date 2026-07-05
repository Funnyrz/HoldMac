import AppKit

final class AppSettings {
    struct ShowBucketShortcut: Equatable {
        let keyCode: UInt32
        let carbonModifiers: UInt32

        var hasRequiredModifier: Bool {
            carbonModifiers != 0
        }
    }

    enum AppLanguage: String, CaseIterable {
        case english
        case chinese

        static func systemDefault() -> AppLanguage {
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            return preferred.hasPrefix("zh") ? .chinese : .english
        }
    }

    enum DragOperation: String, CaseIterable {
        case copy
        case move

        var nsDragOperation: NSDragOperation {
            switch self {
            case .copy:
                return .copy
            case .move:
                return .move
            }
        }

    }

    enum TriggerMode: String, CaseIterable {
        case drag
        case shake
    }

    enum ScreenPlacement: String, CaseIterable {
        case currentDragScreen
        case mainScreen

    }

    private enum Key {
        static let defaultShowBucketShortcutKeyCode = 7
        static let defaultShowBucketShortcutModifiers = ShortcutModifier.control | ShortcutModifier.command

        static let appLanguage = "appLanguage"
        static let triggerMode = "triggerMode"
        static let defaultDragOperation = "defaultDragOperation"
        static let autoHideDelay = "autoHideDelay"
        static let dragTriggerThreshold = "dragTriggerThreshold"
        static let shakeAmplitude = "shakeAmplitude"
        static let screenPlacement = "screenPlacement"
        static let showBucketShortcutKeyCode = "showBucketShortcutKeyCode"
        static let showBucketShortcutModifiers = "showBucketShortcutModifiers"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    var defaultDragOperation: DragOperation {
        get {
            DragOperation(rawValue: defaults.string(forKey: Key.defaultDragOperation) ?? "") ?? .copy
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.defaultDragOperation)
        }
    }

    var appLanguage: AppLanguage {
        get {
            AppLanguage(rawValue: defaults.string(forKey: Key.appLanguage) ?? "") ?? .systemDefault()
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.appLanguage)
        }
    }

    var localizer: Localizer {
        Localizer(language: appLanguage)
    }

    var triggerMode: TriggerMode {
        get {
            TriggerMode(rawValue: defaults.string(forKey: Key.triggerMode) ?? "") ?? .drag
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.triggerMode)
        }
    }

    var autoHideDelay: TimeInterval {
        get {
            clamp(defaults.double(forKey: Key.autoHideDelay), min: 2.0, max: 10.0)
        }
        set {
            defaults.set(clamp(newValue, min: 2.0, max: 10.0), forKey: Key.autoHideDelay)
        }
    }

    var dragTriggerThreshold: CGFloat {
        get {
            CGFloat(clamp(defaults.double(forKey: Key.dragTriggerThreshold), min: 4.0, max: 30.0))
        }
        set {
            defaults.set(clamp(Double(newValue), min: 4.0, max: 30.0), forKey: Key.dragTriggerThreshold)
        }
    }

    var shakeAmplitude: CGFloat {
        get {
            CGFloat(clamp(defaults.double(forKey: Key.shakeAmplitude), min: 40.0, max: 140.0))
        }
        set {
            defaults.set(clamp(Double(newValue), min: 40.0, max: 140.0), forKey: Key.shakeAmplitude)
        }
    }

    var screenPlacement: ScreenPlacement {
        get {
            ScreenPlacement(rawValue: defaults.string(forKey: Key.screenPlacement) ?? "") ?? .currentDragScreen
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.screenPlacement)
        }
    }

    var showBucketShortcut: ShowBucketShortcut? {
        get {
            guard defaults.object(forKey: Key.showBucketShortcutKeyCode) != nil,
                  defaults.object(forKey: Key.showBucketShortcutModifiers) != nil else {
                return nil
            }

            let keyCode = UInt32(defaults.integer(forKey: Key.showBucketShortcutKeyCode))
            let modifiers = UInt32(defaults.integer(forKey: Key.showBucketShortcutModifiers))
            guard modifiers != 0 else { return nil }
            return ShowBucketShortcut(keyCode: keyCode, carbonModifiers: modifiers)
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.showBucketShortcutKeyCode)
                defaults.removeObject(forKey: Key.showBucketShortcutModifiers)
                return
            }

            defaults.set(Int(newValue.keyCode), forKey: Key.showBucketShortcutKeyCode)
            defaults.set(Int(newValue.carbonModifiers), forKey: Key.showBucketShortcutModifiers)
        }
    }

    func shortcutDisplayString(_ shortcut: ShowBucketShortcut?) -> String {
        guard let shortcut else {
            return localizer.text(.shortcutNotSet)
        }

        var parts = ""
        if shortcut.carbonModifiers & ShortcutModifier.command != 0 { parts += "⌘" }
        if shortcut.carbonModifiers & ShortcutModifier.option != 0 { parts += "⌥" }
        if shortcut.carbonModifiers & ShortcutModifier.control != 0 { parts += "⌃" }
        if shortcut.carbonModifiers & ShortcutModifier.shift != 0 { parts += "⇧" }
        parts += keyName(for: shortcut.keyCode)
        return parts
    }

    var allowModifierOverride: Bool {
        true
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.appLanguage: AppLanguage.systemDefault().rawValue,
            Key.triggerMode: TriggerMode.drag.rawValue,
            Key.defaultDragOperation: DragOperation.copy.rawValue,
            Key.autoHideDelay: 5.0,
            Key.dragTriggerThreshold: 10.0,
            Key.shakeAmplitude: 72.0,
            Key.screenPlacement: ScreenPlacement.currentDragScreen.rawValue,
            Key.showBucketShortcutKeyCode: Key.defaultShowBucketShortcutKeyCode,
            Key.showBucketShortcutModifiers: Int(Key.defaultShowBucketShortcutModifiers)
        ])
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private func keyName(for keyCode: UInt32) -> String {
        let names: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            49: "Space", 50: "`", 51: "Delete", 53: "Esc", 65: ".", 67: "*", 69: "+", 71: "Clear",
            75: "/", 76: "Enter", 78: "-", 81: "=", 82: "0", 83: "1", 84: "2", 85: "3", 86: "4",
            87: "5", 88: "6", 89: "7", 91: "8", 92: "9", 96: "F5", 97: "F6", 98: "F7",
            99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13", 106: "F16", 107: "F14",
            109: "F10", 111: "F12", 113: "F15", 114: "Help", 115: "Home", 116: "Page Up",
            117: "Forward Delete", 118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return names[keyCode] ?? "Key \(keyCode)"
    }
}
