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
            return cached
        }

        let (data, _) = try await session.data(from: url)
        cacheManager.cache(data: data, forKey: key)
        return data
    }
}
