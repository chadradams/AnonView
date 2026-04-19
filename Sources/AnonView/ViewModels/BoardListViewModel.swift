#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class BoardListViewModel: ObservableObject {
    @Published public private(set) var boards: [Board] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let apiClient: APIClient
    private let cacheManager: CacheManager

    public init(apiClient: APIClient = APIClient(), cacheManager: CacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }

    public func loadBoards(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let cacheKey = "json:boards"

        if !forceRefresh,
           let cached = cacheManager.cachedData(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(BoardListResponse.self, from: cached) {
            boards = decoded.boards
            return
        }

        do {
            let remoteBoards = try await apiClient.fetchBoards()
            boards = remoteBoards.sorted { $0.id < $1.id }
            let payload = try JSONEncoder().encode(BoardListResponse(boards: boards))
            cacheManager.cache(data: payload, forKey: cacheKey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
