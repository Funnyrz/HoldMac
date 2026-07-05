import Foundation

struct BucketItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var displayName: String {
        FileManager.default.displayName(atPath: url.path)
    }
}
