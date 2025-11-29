import Foundation

/// Least Recently Used (LRU) Cache implementation
class LRUCache<Key: Hashable, Value> {
    private var cache: [Key: Value] = [:]
    private var order: [Key] = []
    private let maxSize: Int

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    subscript(key: Key) -> Value? {
        get {
            guard let value = cache[key] else { return nil }
            // Move to end (most recently used)
            if let index = order.firstIndex(of: key) {
                order.remove(at: index)
                order.append(key)
            }
            return value
        }
        set {
            if let newValue = newValue {
                // Add or update
                cache[key] = newValue
                if let index = order.firstIndex(of: key) {
                    order.remove(at: index)
                }
                order.append(key)

                // Evict oldest if over capacity
                if order.count > maxSize {
                    let oldestKey = order.removeFirst()
                    cache.removeValue(forKey: oldestKey)
                }
            } else {
                // Remove
                cache.removeValue(forKey: key)
                if let index = order.firstIndex(of: key) {
                    order.remove(at: index)
                }
            }
        }
    }

    func removeAll() {
        cache.removeAll()
        order.removeAll()
    }

    var count: Int {
        return cache.count
    }
}
