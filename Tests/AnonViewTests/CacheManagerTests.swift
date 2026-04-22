import Foundation
import Testing
@testable import AnonView

private let staleEntryAgeOffset: TimeInterval = 7_200

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

@Test func cacheManagerExpiresStaleEntriesOnRead() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let manager = CacheManager(baseDirectoryURL: directory, maxCacheAge: 60)

    let payload = Data("stale".utf8)
    manager.cache(data: payload, forKey: "stale-key")

    let files = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    #expect(files.count == 1)
    if let fileURL = files.first {
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: -staleEntryAgeOffset)],
            ofItemAtPath: fileURL.path
        )
    }

    #expect(manager.cachedData(forKey: "stale-key") == nil)
    try manager.clear()
}

@Test func cacheManagerRemovesExpiredEntriesDuringCleanup() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let manager = CacheManager(baseDirectoryURL: directory, maxCacheAge: 60)

    let stalePayload = Data("old".utf8)
    let freshPayload = Data("new".utf8)
    manager.cache(data: stalePayload, forKey: "old-key")

    var files = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    #expect(files.count == 1)
    let staleFileURL = files[0]
    try FileManager.default.setAttributes(
        [.modificationDate: Date(timeIntervalSinceNow: -staleEntryAgeOffset)],
        ofItemAtPath: staleFileURL.path
    )

    manager.cache(data: freshPayload, forKey: "new-key")
    manager.removeExpiredEntries()

    #expect(manager.cachedData(forKey: "old-key") == nil)
    #expect(manager.cachedData(forKey: "new-key") == freshPayload)

    files = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    #expect(files.count == 1)

    try manager.clear()
}
