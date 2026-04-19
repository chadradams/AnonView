#if canImport(SwiftUI)
import SwiftUI

public struct BoardListView: View {
    @StateObject private var viewModel = BoardListViewModel()
    private let selection: Binding<Board?>?

    public init(selection: Binding<Board?>? = nil) {
        self.selection = selection
    }

    public var body: some View {
        Group {
            if let selection {
                List(viewModel.boards, selection: selection) { board in
                    boardRow(board)
                        .tag(board)
                }
            } else {
                List(viewModel.boards) { board in
                    NavigationLink(value: board) {
                        boardRow(board)
                    }
                }
            }
        }
        .navigationTitle("Boards")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
            }
        }
        .task { await viewModel.loadBoards() }
        .refreshable { await viewModel.loadBoards(forceRefresh: true) }
    }

    private func boardRow(_ board: Board) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("/\(board.id)/")
                .font(.headline)
            Text(board.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
