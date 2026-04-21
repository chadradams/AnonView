import Foundation

public struct ImageAttachment: Codable, Hashable, Sendable {
    public let tim: Int
    public let ext: String

    public enum MediaType: Sendable {
        case image
        case animatedGIF
        case video
    }

    public init(tim: Int, ext: String) {
        self.tim = tim
        self.ext = ext
    }

    public var mediaType: MediaType {
        switch ext.lowercased() {
        case ".gif": return .animatedGIF
        case ".webm", ".mp4": return .video
        default: return .image
        }
    }

    public var isVideo: Bool { mediaType == .video }

    public func imageURL(boardID: String) -> URL? {
        URL(string: "https://i.4cdn.org/\(boardID)/\(tim)\(ext)")
    }

    public func thumbnailURL(boardID: String) -> URL? {
        URL(string: "https://i.4cdn.org/\(boardID)/\(tim)s.jpg")
    }
}
