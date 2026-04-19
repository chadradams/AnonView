import Foundation

public struct CatalogPage: Codable, Sendable {
    public let page: Int
    public let threads: [ThreadSummary]
}

public struct ThreadResponse: Codable, Sendable {
    public let posts: [Post]
}

public struct ThreadSummary: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let subject: String?
    public let comment: String?
    public let author: String?
    public let timestamp: TimeInterval
    public let replyCount: Int
    public let imageCount: Int
    public let attachment: ImageAttachment?
    public let spoiler: Bool

    enum CodingKeys: String, CodingKey {
        case no, sub, com, name, time, replies, images, tim, ext, spoiler
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .no)
        subject = try container.decodeIfPresent(String.self, forKey: .sub)
        comment = try container.decodeIfPresent(String.self, forKey: .com)
        author = try container.decodeIfPresent(String.self, forKey: .name)
        timestamp = try container.decode(TimeInterval.self, forKey: .time)
        replyCount = try container.decodeIfPresent(Int.self, forKey: .replies) ?? 0
        imageCount = try container.decodeIfPresent(Int.self, forKey: .images) ?? 0
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
        try container.encodeIfPresent(subject, forKey: .sub)
        try container.encodeIfPresent(comment, forKey: .com)
        try container.encodeIfPresent(author, forKey: .name)
        try container.encode(timestamp, forKey: .time)
        try container.encode(replyCount, forKey: .replies)
        try container.encode(imageCount, forKey: .images)
        try container.encode(spoiler ? 1 : 0, forKey: .spoiler)
        try container.encodeIfPresent(attachment?.tim, forKey: .tim)
        try container.encodeIfPresent(attachment?.ext, forKey: .ext)
    }
}
