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

    public init(boardID: String, threadID: Int, apiClient: APIClient = APIClient(), cacheManager: CacheManager = .shared) {
        self.boardID = boardID
        self.threadID = threadID
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }

    public func loadPosts(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let cacheKey = "json:thread:\(boardID):\(threadID)"
        if !forceRefresh,
           let cached = cacheManager.cachedData(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([Post].self, from: cached) {
            posts = decoded.sorted { $0.timestamp < $1.timestamp }
            return
        }

        do {
            let remotePosts = try await apiClient.fetchThread(boardID: boardID, threadID: threadID)
            posts = remotePosts
            cacheManager.cache(data: try JSONEncoder().encode(remotePosts), forKey: cacheKey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
