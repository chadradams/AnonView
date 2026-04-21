#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class ThreadViewModel: ObservableObject {
    @Published public private(set) var posts: [Post] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let boardID: String
    private let threadID: Int
    private let apiClient: APIClient
    private let cacheManager: CacheManager
    private let imageLoader: ImageLoader

    public init(boardID: String, threadID: Int, apiClient: APIClient = APIClient(), cacheManager: CacheManager = .shared) {
        self.boardID = boardID
        self.threadID = threadID
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        self.imageLoader = ImageLoader(cacheManager: cacheManager)
    }

    public func loadPosts(forceRefresh: Bool = false) async {
        AppLogger.info("Loading posts for /\(boardID)/ thread \(threadID) (forceRefresh: \(forceRefresh))")
        isLoading = true
        defer { isLoading = false }

        let cacheKey = "json:thread:\(boardID):\(threadID)"
        if !forceRefresh,
           let cached = cacheManager.cachedData(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([Post].self, from: cached) {
            AppLogger.info("Loaded posts from cache for /\(boardID)/ thread \(threadID): \(decoded.count)")
            posts = decoded.sorted { $0.timestamp < $1.timestamp }
            return
        }

        do {
            let remotePosts = try await apiClient.fetchThread(boardID: boardID, threadID: threadID)
            posts = remotePosts
            cacheManager.cache(data: try JSONEncoder().encode(remotePosts), forKey: cacheKey)
            AppLogger.info("Loaded posts from network for /\(boardID)/ thread \(threadID): \(remotePosts.count)")
            let thumbURLs = remotePosts.compactMap { $0.attachment?.thumbnailURL(boardID: boardID) }
            imageLoader.prefetch(urls: thumbURLs)
            errorMessage = nil
        } catch {
            AppLogger.error("Failed to load posts for /\(boardID)/ thread \(threadID): \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
#endif
