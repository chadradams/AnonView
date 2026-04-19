#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class ThreadListViewModel: ObservableObject {
    @Published public private(set) var threads: [ThreadSummary] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let board: Board
    private let apiClient: APIClient
    private let cacheManager: CacheManager

    public init(board: Board, apiClient: APIClient = APIClient(), cacheManager: CacheManager = .shared) {
        self.board = board
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }

    public func loadThreads(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let cacheKey = "json:catalog:\(board.id)"
        if !forceRefresh,
           let cached = cacheManager.cachedData(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([ThreadSummary].self, from: cached) {
            threads = decoded
            return
        }

        do {
            let remoteThreads = try await apiClient.fetchCatalog(boardID: board.id)
            threads = remoteThreads
            cacheManager.cache(data: try JSONEncoder().encode(remoteThreads), forKey: cacheKey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
