import Foundation
import Testing
@testable import AnonView

@Test func cacheManagerRoundTripsData() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let manager = CacheManager(baseDirectoryURL: directory)

    let payload = Data("hello".utf8)
    manager.cache(data: payload, forKey: "sample-key")

    #expect(manager.cachedData(forKey: "sample-key") == payload)

    try manager.clear()
    #expect(manager.cachedData(forKey: "sample-key") == nil)
}
