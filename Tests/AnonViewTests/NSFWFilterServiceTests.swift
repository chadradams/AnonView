import Foundation
import Testing
@testable import AnonView

@Test func nsfwDefaultsToBlurEnabledAndDetectsCommonCases() {
    let suiteName = "anonview-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let service = NSFWFilterService(defaults: defaults)

    #expect(service.blurNSFWImages)
    #expect(service.isNSFW(boardID: "b", boardIsWorksafe: false, spoiler: false, subject: nil))
    #expect(service.isNSFW(boardID: "g", boardIsWorksafe: true, spoiler: true, subject: nil))
    #expect(service.isNSFW(boardID: "g", boardIsWorksafe: true, spoiler: false, subject: "NSFW warning"))
    #expect(!service.isNSFW(boardID: "g", boardIsWorksafe: true, spoiler: false, subject: "Safe thread"))

    service.blurNSFWImages = false
    #expect(!service.blurNSFWImages)
}
