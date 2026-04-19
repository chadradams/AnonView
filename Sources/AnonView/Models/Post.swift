import Foundation

public struct Post: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let threadID: Int
    public let author: String?
    public let timestamp: TimeInterval
    public let comment: String?
    public let spoiler: Bool
    public let subject: String?
    public let attachment: ImageAttachment?

    enum CodingKeys: String, CodingKey {
        case no, resto, name, time, com, spoiler, sub, tim, ext
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .no)
        threadID = try container.decodeIfPresent(Int.self, forKey: .resto) ?? id
        author = try container.decodeIfPresent(String.self, forKey: .name)
        timestamp = try container.decode(TimeInterval.self, forKey: .time)
        comment = try container.decodeIfPresent(String.self, forKey: .com)
        subject = try container.decodeIfPresent(String.self, forKey: .sub)
        spoiler = (try container.decodeIfPresent(Int.self, forKey: .spoiler) ?? 0) == 1

        if let tim = try container.decodeIfPresent(Int.self, forKey: .tim),
           let ext = try container.decodeIfPresent(String.self, forKey: .ext) {
            attachment = ImageAttachment(tim: tim, ext: ext)
        } else {
            attachment = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .no)
        try container.encode(threadID, forKey: .resto)
        try container.encodeIfPresent(author, forKey: .name)
        try container.encode(timestamp, forKey: .time)
        try container.encodeIfPresent(comment, forKey: .com)
        try container.encode(spoiler ? 1 : 0, forKey: .spoiler)
        try container.encodeIfPresent(subject, forKey: .sub)
        try container.encodeIfPresent(attachment?.tim, forKey: .tim)
        try container.encodeIfPresent(attachment?.ext, forKey: .ext)
    }
}
