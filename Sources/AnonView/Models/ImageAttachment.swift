import Foundation

public struct ImageAttachment: Codable, Hashable, Sendable {
    public let tim: Int
    public let ext: String

    public init(tim: Int, ext: String) {
        self.tim = tim
        self.ext = ext
    }

    public func imageURL(boardID: String) -> URL? {
        URL(string: "https://i.4cdn.org/\(boardID)/\(tim)\(ext)")
    }

    public func thumbnailURL(boardID: String) -> URL? {
        URL(string: "https://i.4cdn.org/\(boardID)/\(tim)s.jpg")
    }
}
