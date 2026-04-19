import Foundation

public struct BoardListResponse: Codable, Sendable {
    public let boards: [Board]
}

public struct Board: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let isWorksafe: Bool

    enum CodingKeys: String, CodingKey {
        case board
        case title
        case wsBoard = "ws_board"
    }

    public init(id: String, title: String, isWorksafe: Bool) {
        self.id = id
        self.title = title
        self.isWorksafe = isWorksafe
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .board)
        title = try container.decode(String.self, forKey: .title)
        isWorksafe = (try container.decodeIfPresent(Int.self, forKey: .wsBoard) ?? 0) == 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .board)
        try container.encode(title, forKey: .title)
        try container.encode(isWorksafe ? 1 : 0, forKey: .wsBoard)
    }
}
