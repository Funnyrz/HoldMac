import AppKit

enum DragOperationPrompt {
    @MainActor
    static func selectedPostCopyOperation(settings: AppSettings) -> AppSettings.DragOperation? {
        let l10n = settings.localizer
        let alert = NSAlert()
        alert.messageText = l10n.text(.chooseDragOperationTitle)
        alert.informativeText = l10n.text(.chooseDragOperationDetail)
        alert.alertStyle = .informational
        alert.addButton(withTitle: l10n.text(.copy))
        alert.addButton(withTitle: l10n.text(.move))
        alert.addButton(withTitle: l10n.text(.cancel))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .copy
        case .alertSecondButtonReturn:
            return .move
        default:
            return nil
        }
    }

    static func operationMask(settings: AppSettings, override: NSDragOperation?) -> NSDragOperation {
        if let override {
            return override
        }

        guard settings.allowModifierOverride else {
            return settings.defaultDragOperation.nsDragOperation
        }

        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            return .move
        }

        return settings.defaultDragOperation.nsDragOperation
    }

    @MainActor
    static func moveOriginalsToTrash(_ urls: Set<URL>, settings: AppSettings) -> Set<URL> {
        var movedURLs = Set<URL>()
        var failedNames: [String] = []

        for url in urls {
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
                movedURLs.insert(url)
            } catch {
                failedNames.append(url.lastPathComponent)
            }
        }

        if failedNames.isEmpty == false {
            let l10n = settings.localizer
            let alert = NSAlert()
            alert.messageText = l10n.text(.moveOriginalsFailedTitle)
            alert.informativeText = l10n.text(.moveOriginalsFailedDetail)
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        return movedURLs
    }
}
