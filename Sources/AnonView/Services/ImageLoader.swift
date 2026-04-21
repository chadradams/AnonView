import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct ImageLoader: Sendable {
    private let session: URLSession
    private let cacheManager: CacheManager

    public init(session: URLSession = .shared, cacheManager: CacheManager = .shared) {
        self.session = session
        self.cacheManager = cacheManager
    }

    public func loadImageData(url: URL) async throws -> Data {
        let key = "image:\(url.absoluteString)"
        if let cached = cacheManager.cachedData(forKey: key) {
            AppLogger.info("Loaded image from cache: \(url.absoluteString)")
            return cached
        }

        AppLogger.info("Downloading image: \(url.absoluteString)")
        let (data, _) = try await session.data(from: url)
        cacheManager.cache(data: data, forKey: key)
        return data
    }

    /// Warms the cache for the given URLs by downloading them in the background.
    /// At most `maxCount` URLs are prefetched; already-cached URLs are skipped.
    /// Errors are silently ignored so prefetch never interferes with foreground work.
    public func prefetch(urls: [URL], maxCount: Int = 8) {
        let uncachedURLs = urls.prefix(maxCount).filter { url in
            cacheManager.cachedData(forKey: "image:\(url.absoluteString)") == nil
        }
        guard !uncachedURLs.isEmpty else { return }

        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in uncachedURLs {
                    group.addTask {
                        _ = try? await self.loadImageData(url: url)
                    }
                }
            }
        }
    }
}
