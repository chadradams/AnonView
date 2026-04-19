import Foundation

public final class CacheManager: @unchecked Sendable {
    public static let shared = CacheManager()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: FileManager
    private let baseDirectoryURL: URL

    public init(fileManager: FileManager = .default, baseDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        if let baseDirectoryURL {
            self.baseDirectoryURL = baseDirectoryURL
        } else {
            let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.baseDirectoryURL = root.appendingPathComponent("AnonViewCache", isDirectory: true)
        }

        memoryCache.countLimit = 256
        memoryCache.totalCostLimit = 128 * 1_024 * 1_024
        try? fileManager.createDirectory(at: self.baseDirectoryURL, withIntermediateDirectories: true)
    }

    public func cachedData(forKey key: String) -> Data? {
        if let inMemory = memoryCache.object(forKey: key as NSString) {
            return inMemory as Data
        }

        let fileURL = pathForKey(key)
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

    private func pathForKey(_ key: String) -> URL {
        let safeName = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return baseDirectoryURL.appendingPathComponent(safeName)
    }
}
