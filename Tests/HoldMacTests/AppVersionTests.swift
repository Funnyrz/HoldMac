import Testing
@testable import HoldMac

struct AppVersionTests {
    @Test
    func readsVersionFieldsFromInfoDictionary() {
        let version = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "100"
        ])

        #expect(version.shortVersion == "1.0")
        #expect(version.buildNumber == "100")
    }

    @Test
    func usesFallbackForMissingVersionFields() {
        let version = AppVersion(infoDictionary: nil)

        #expect(version.shortVersion == AppVersion.unknownValue)
        #expect(version.buildNumber == AppVersion.unknownValue)
    }

    @Test
    func formatsLocalizedVersionText() {
        let version = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "100"
        ])

        #expect(version.localizedDescription(localizer: Localizer(language: .english)) == "Version 1.0 (100)")
        #expect(version.localizedDescription(localizer: Localizer(language: .chinese)) == "版本 1.0 (100)")
    }
}
