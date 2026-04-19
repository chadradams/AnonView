import Foundation

public final class NSFWFilterService: @unchecked Sendable {
    public static let blurSettingKey = "anonview.blurNSFW"

    private let defaults: UserDefaults
    private let nsfwBoards: Set<String>

    public init(defaults: UserDefaults = .standard, nsfwBoards: Set<String> = ["b", "gif", "pol", "r9k", "s", "soc", "hr"]) {
        self.defaults = defaults
        self.nsfwBoards = nsfwBoards

        if defaults.object(forKey: Self.blurSettingKey) == nil {
            defaults.set(true, forKey: Self.blurSettingKey)
        }
    }

    public var blurNSFWImages: Bool {
        get { defaults.bool(forKey: Self.blurSettingKey) }
        set { defaults.set(newValue, forKey: Self.blurSettingKey) }
    }

    public func isNSFW(boardID: String, boardIsWorksafe: Bool, spoiler: Bool, subject: String?) -> Bool {
        if spoiler { return true }
        if !boardIsWorksafe || nsfwBoards.contains(boardID.lowercased()) { return true }
        guard let subject else { return false }
        let lower = subject.lowercased()
        return lower.contains("nsfw") || lower.contains("explicit") || lower.contains("adult")
    }
}
