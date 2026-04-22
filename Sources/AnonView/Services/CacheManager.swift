import Foundation

public final class CacheManager: @unchecked Sendable {
    public static let shared = CacheManager()
    public static let defaultMaxCacheAge: TimeInterval = 24 * 60 * 60

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: FileManager
    private let baseDirectoryURL: URL
    private let maxCacheAge: TimeInterval

    public init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil,
        maxCacheAge: TimeInterval = CacheManager.defaultMaxCacheAge
    ) {
        self.fileManager = fileManager
        self.maxCacheAge = maxCacheAge
        if let baseDirectoryURL {
            self.baseDirectoryURL = baseDirectoryURL
        } else {
            let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.baseDirectoryURL = root.appendingPathComponent("AnonViewCache", isDirectory: true)
        }

        memoryCache.countLimit = 256
        memoryCache.totalCostLimit = 128 * 1_024 * 1_024
        try? fileManager.createDirectory(at: self.baseDirectoryURL, withIntermediateDirectories: true)
        removeExpiredEntries()
    }

    public func cachedData(forKey key: String) -> Data? {
        if let inMemory = memoryCache.object(forKey: key as NSString) {
            return inMemory as Data
        }

        let fileURL = pathForKey(key)
        if isExpired(fileURL: fileURL) {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        return data
    }

    public func cache(data: Data, forKey key: String) {
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        try? data.write(to: pathForKey(key), options: .atomic)
    }

    public func clear() throws {
        memoryCache.removeAllObjects()
        if fileManager.fileExists(atPath: baseDirectoryURL.path) {
            try fileManager.removeItem(at: baseDirectoryURL)
        }
        try fileManager.createDirectory(at: baseDirectoryURL, withIntermediateDirectories: true)
    }

    public func removeExpiredEntries(now: Date = Date()) {
        guard maxCacheAge > 0 else { return }

        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: baseDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for fileURL in fileURLs where isExpired(fileURL: fileURL, now: now) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    private func pathForKey(_ key: String) -> URL {
        let safeName = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return baseDirectoryURL.appendingPathComponent(safeName)
    }

    private func isExpired(fileURL: URL, now: Date = Date()) -> Bool {
        guard maxCacheAge > 0 else { return false }
        guard let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
              let modificationDate = values.contentModificationDate else {
            return false
        }
        return now.timeIntervalSince(modificationDate) > maxCacheAge
    }
}
