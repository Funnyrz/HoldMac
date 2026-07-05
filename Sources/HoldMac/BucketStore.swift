import Foundation

@MainActor
final class BucketStore {
    private(set) var items: [BucketItem] = []
    var onChange: (() -> Void)?

    func append(_ urls: [URL]) {
        var known = Set(items.map(\.url))
        var changed = false
        for url in urls where known.insert(url).inserted {
            items.append(BucketItem(url: url))
            changed = true
        }
        if changed {
            notifyChange()
        }
    }

    func clear() {
        guard items.isEmpty == false else { return }
        items.removeAll()
        notifyChange()
    }

    func remove(_ item: BucketItem) {
        remove(urls: [item.url])
    }

    func remove(urls: Set<URL>) {
        guard urls.isEmpty == false else { return }
        let originalCount = items.count
        items.removeAll { urls.contains($0.url) }
        if items.count != originalCount {
            notifyChange()
        }
    }

    private func notifyChange() {
        onChange?()
    }
}
