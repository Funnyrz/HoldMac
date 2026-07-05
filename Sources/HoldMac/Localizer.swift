import Foundation

struct Localizer {
    enum Key: String {
        case languageEnglish
        case languageChinese
        case settingsMenu
        case showBucket
        case clearBucket
        case clearBucketInline
        case quitBucket
        case settingsTitle
        case settingsSubtitle
        case language
        case languageDetail
        case triggerMode
        case triggerModeDetail
        case triggerDrag
        case triggerShake
        case shakeAmplitude
        case shakeAmplitudeDetail
        case showBucketShortcut
        case showBucketShortcutDetail
        case shortcutRecord
        case shortcutClear
        case shortcutNotSet
        case shortcutRecording
        case copy
        case move
        case currentScreen
        case mainScreen
        case defaultDragOut
        case defaultDragOutDetail
        case autoHide
        case autoHideDetail
        case triggerSensitivity
        case triggerSensitivityDetail
        case display
        case displayDetail
        case bucketContents
        case bucketContentsDetail
        case modifierNote
        case dropFilesHere
        case bucketListTitle
        case bucketListEmpty
        case removeItem
        case pathUnavailable
        case chooseDragOperationTitle
        case chooseDragOperationDetail
        case cancel
        case moveOriginalsFailedTitle
        case moveOriginalsFailedDetail
        case itemSingular
        case itemPlural
    }

    private let language: AppSettings.AppLanguage

    init(language: AppSettings.AppLanguage) {
        self.language = language
    }

    func text(_ key: Key) -> String {
        switch language {
        case .english:
            return english[key] ?? key.rawValue
        case .chinese:
            return chinese[key] ?? english[key] ?? key.rawValue
        }
    }

    private var english: [Key: String] {
        [
            .languageEnglish: "English",
            .languageChinese: "中文",
            .settingsMenu: "Settings...",
            .showBucket: "Show Hold Area",
            .clearBucket: "Clear Hold Area",
            .clearBucketInline: "Clear",
            .quitBucket: "Quit File Transit Bucket",
            .settingsTitle: "File Transit Bucket Settings",
            .settingsSubtitle: "Tune how the hold area appears and how files leave it.",
            .language: "Language",
            .languageDetail: "Choose the interface language.",
            .triggerMode: "Trigger mode",
            .triggerModeDetail: "Show the hold area immediately during a Finder drag, or only after a shake gesture.",
            .triggerDrag: "Drag",
            .triggerShake: "Shake",
            .shakeAmplitude: "Shake amplitude",
            .shakeAmplitudeDetail: "How much back-and-forth movement is required before the hold area appears.",
            .showBucketShortcut: "Show hold area shortcut",
            .showBucketShortcutDetail: "Record a global shortcut for showing the hold area manually.",
            .shortcutRecord: "Record",
            .shortcutClear: "Clear",
            .shortcutNotSet: "Not set",
            .shortcutRecording: "Press shortcut...",
            .copy: "Copy",
            .move: "Move",
            .currentScreen: "Current Screen",
            .mainScreen: "Main Screen",
            .defaultDragOut: "Default drag out",
            .defaultDragOutDetail: "Choose whether leaving the hold area starts as copy or move.",
            .autoHide: "Auto hide",
            .autoHideDetail: "How long the hold area stays visible after appearing.",
            .triggerSensitivity: "Trigger sensitivity",
            .triggerSensitivityDetail: "Drag distance needed before the hold area appears.",
            .display: "Display",
            .displayDetail: "Where the hold area appears during Finder drags.",
            .bucketContents: "Hold area contents",
            .bucketContentsDetail: "Remove all temporary file references now.",
            .modifierNote: "Modifier keys can still override the default copy/move operation during a Finder drop.",
            .dropFilesHere: "Drop files here",
            .bucketListTitle: "Hold Area Contents",
            .bucketListEmpty: "The hold area is empty.",
            .removeItem: "Remove",
            .pathUnavailable: "Path unavailable",
            .chooseDragOperationTitle: "Choose Drag Operation",
            .chooseDragOperationDetail: "Keep the copied items, or move the originals to Trash?",
            .cancel: "Cancel",
            .moveOriginalsFailedTitle: "Some originals could not be moved",
            .moveOriginalsFailedDetail: "The copied items were left in place. Any originals that could not be moved remain in the hold area.",
            .itemSingular: "item",
            .itemPlural: "items"
        ]
    }

    private var chinese: [Key: String] {
        [
            .languageEnglish: "English",
            .languageChinese: "中文",
            .settingsMenu: "设置...",
            .showBucket: "显示文件中转桶",
            .clearBucket: "清空文件中转桶",
            .clearBucketInline: "清空",
            .quitBucket: "退出文件中转桶",
            .settingsTitle: "文件中转桶设置",
            .settingsSubtitle: "调整文件中转桶的显示方式，以及文件拖出时的默认行为。",
            .language: "语言",
            .languageDetail: "选择界面显示语言。",
            .triggerMode: "触发方式",
            .triggerModeDetail: "在 Finder 拖动时立即显示文件中转桶，或仅在拖动并晃动后显示。",
            .triggerDrag: "拖动",
            .triggerShake: "晃动",
            .shakeAmplitude: "晃动幅度",
            .shakeAmplitudeDetail: "需要多大幅度的来回晃动才显示文件中转桶。",
            .showBucketShortcut: "显示中转桶快捷键",
            .showBucketShortcutDetail: "录制一个全局快捷键，用于主动显示文件中转桶。",
            .shortcutRecord: "录制",
            .shortcutClear: "清除",
            .shortcutNotSet: "未设置",
            .shortcutRecording: "请按快捷键...",
            .copy: "复制",
            .move: "移动",
            .currentScreen: "当前屏幕",
            .mainScreen: "主屏幕",
            .defaultDragOut: "默认拖出操作",
            .defaultDragOutDetail: "选择文件离开中转桶时默认复制还是移动。",
            .autoHide: "自动隐藏",
            .autoHideDetail: "文件中转桶出现后保持可见的时间。",
            .triggerSensitivity: "触发灵敏度",
            .triggerSensitivityDetail: "拖动多远后才显示文件中转桶。",
            .display: "显示位置",
            .displayDetail: "Finder 拖动时文件中转桶出现在哪个屏幕。",
            .bucketContents: "中转桶内容",
            .bucketContentsDetail: "立即移除所有临时文件引用。",
            .modifierNote: "拖到 Finder 时，修饰键仍可临时覆盖默认复制/移动操作。",
            .dropFilesHere: "把文件拖到这里",
            .bucketListTitle: "中转桶内容",
            .bucketListEmpty: "中转桶是空的。",
            .removeItem: "移除",
            .pathUnavailable: "路径不可用",
            .chooseDragOperationTitle: "选择拖出操作",
            .chooseDragOperationDetail: "保留复制结果，还是将原始文件移到废纸篓？",
            .cancel: "取消",
            .moveOriginalsFailedTitle: "部分原始文件无法移动",
            .moveOriginalsFailedDetail: "复制结果已保留。无法移动的原始文件仍保留在中转桶中。",
            .itemSingular: "项",
            .itemPlural: "项"
        ]
    }
}
