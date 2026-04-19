#if canImport(SwiftUI)
import SwiftUI

public struct ThreadListView: View {
    private let board: Board
    private let selection: Binding<ThreadSummary?>?
    @StateObject private var viewModel: ThreadListViewModel

    public init(board: Board, selection: Binding<ThreadSummary?>? = nil) {
        self.board = board
        self.selection = selection
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(board: board))
    }

    public var body: some View {
        Group {
            if let selection {
                List(viewModel.threads, selection: selection) { thread in
                    threadRow(thread)
                        .tag(thread)
                }
            } else {
                List(viewModel.threads) { thread in
                    NavigationLink(value: thread) {
                        threadRow(thread)
                    }
                }
            }
        }
        .navigationTitle("/\(board.id)/")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
            }
        }
        .task { await viewModel.loadThreads() }
        .refreshable { await viewModel.loadThreads(forceRefresh: true) }
    }

    private func threadRow(_ thread: ThreadSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let subject = thread.subject, !subject.isEmpty {
                Text(subject)
                    .font(.headline)
                    .lineLimit(2)
            }
            if let comment = thread.comment {
                Text(comment.lightlyParsedHTML)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack {
                Label("\(thread.replyCount)", systemImage: "text.bubble")
                Label("\(thread.imageCount)", systemImage: "photo")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
#endif
