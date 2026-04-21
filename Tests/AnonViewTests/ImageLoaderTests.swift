import Foundation
import Testing
@testable import AnonView

@Test func imageLoaderCachesDownloadedData() async throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let cache = CacheManager(baseDirectoryURL: directory)

    let payload = Data("fake-image".utf8)
    let url = URL(string: "https://example.com/test.gif")!

    // Seed the cache so no real network call is made.
    cache.cache(data: payload, forKey: "image:\(url.absoluteString)")

    let loader = ImageLoader(cacheManager: cache)
    let data = try await loader.loadImageData(url: url)
    #expect(data == payload)

    try cache.clear()
}

@Test func imageLoaderPrefetchSkipsAlreadyCachedURLs() async throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let cache = CacheManager(baseDirectoryURL: directory)

    let url = URL(string: "https://example.com/thumb.jpg")!
    let payload = Data("thumb".utf8)
    cache.cache(data: payload, forKey: "image:\(url.absoluteString)")

    // Prefetch with an already-cached URL: the cached value must remain intact.
    let loader = ImageLoader(cacheManager: cache)
    loader.prefetch(urls: [url])

    #expect(cache.cachedData(forKey: "image:\(url.absoluteString)") == payload)

    try cache.clear()
}
