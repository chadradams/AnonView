import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor RequestThrottler {
    private let minInterval: TimeInterval
    private var lastRequestDate: Date?

    public init(minInterval: TimeInterval = 0.35) {
        self.minInterval = minInterval
    }

    public func waitIfNeeded() async {
        guard let lastRequestDate else {
            self.lastRequestDate = Date()
            return
        }

        let delta = Date().timeIntervalSince(lastRequestDate)
        if delta < minInterval {
            let waitTime = minInterval - delta
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        self.lastRequestDate = Date()
    }
}

public struct APIClient: Sendable {
    public enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpStatus(Int)

        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response"
            case .httpStatus(let status):
                return "Request failed with status \(status)"
            }
        }
    }

    private let decoder = JSONDecoder()
    private let session: URLSession
    private let throttler: RequestThrottler
    private let maxRetryCount: Int

    public init(session: URLSession = .shared, throttler: RequestThrottler = RequestThrottler(), maxRetryCount: Int = 2) {
        self.session = session
        self.throttler = throttler
        self.maxRetryCount = max(0, maxRetryCount)
    }

    public func boardsURL() -> URL? {
        URL(string: "https://a.4cdn.org/boards.json")
    }

    public func catalogURL(boardID: String) -> URL? {
        URL(string: "https://a.4cdn.org/\(boardID)/catalog.json")
    }

    public func threadURL(boardID: String, threadID: Int) -> URL? {
        URL(string: "https://a.4cdn.org/\(boardID)/thread/\(threadID).json")
    }

    public func fetchBoards() async throws -> [Board] {
        guard let url = boardsURL() else { throw APIError.invalidURL }
        let response: BoardListResponse = try await request(url)
        return response.boards
    }

    public func fetchCatalog(boardID: String) async throws -> [ThreadSummary] {
        guard let url = catalogURL(boardID: boardID) else { throw APIError.invalidURL }
        let pages: [CatalogPage] = try await request(url)
        return pages.flatMap(\.threads)
    }

    public func fetchThread(boardID: String, threadID: Int) async throws -> [Post] {
        guard let url = threadURL(boardID: boardID, threadID: threadID) else { throw APIError.invalidURL }
        let response: ThreadResponse = try await request(url)
        return response.posts.sorted { $0.timestamp < $1.timestamp }
    }

    private func request<Response: Decodable>(_ url: URL) async throws -> Response {
        var lastError: Error?

        for attempt in 0...maxRetryCount {
            do {
                await throttler.waitIfNeeded()

                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                guard 200..<300 ~= http.statusCode else {
                    throw APIError.httpStatus(http.statusCode)
                }
                return try decoder.decode(Response.self, from: data)
            } catch {
                lastError = error
                if attempt == maxRetryCount {
                    throw error
                }
                let backoff = UInt64(pow(2.0, Double(attempt)) * 250_000_000)
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        throw lastError ?? APIError.invalidResponse
    }
}
