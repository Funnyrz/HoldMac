import Foundation

struct AppVersion: Equatable {
    static let unknownValue = "Unknown"

    let shortVersion: String
    let buildNumber: String

    init(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        shortVersion = Self.stringValue(for: "CFBundleShortVersionString", in: infoDictionary) ?? Self.unknownValue
        buildNumber = Self.stringValue(for: "CFBundleVersion", in: infoDictionary) ?? Self.unknownValue
    }

    func localizedDescription(localizer: Localizer) -> String {
        String(format: localizer.text(.softwareVersionFormat), shortVersion, buildNumber)
    }

    private static func stringValue(for key: String, in infoDictionary: [String: Any]?) -> String? {
        guard let value = infoDictionary?[key] as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
