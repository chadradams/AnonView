#if canImport(SwiftUI)
import SwiftUI

public struct ThreadListView: View {
    private let board: Board
    private let selection: Binding<ThreadSummary?>?
    @StateObject private var viewModel: ThreadListViewModel
    @State private var searchText = ""
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    public init(board: Board, selection: Binding<ThreadSummary?>? = nil) {
        self.board = board
        self.selection = selection
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(board: board))
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredThreads(matching: searchText)) { thread in
                    if let selection {
                        Button {
                            selection.wrappedValue = thread
                        } label: {
                            threadCard(thread, isSelected: selection.wrappedValue?.id == thread.id)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: thread) {
                            threadCard(thread, isSelected: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle("/\(board.id)/")
        .searchable(text: $searchText, prompt: "Search threads")
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

    private func threadCard(_ thread: ThreadSummary, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let attachment = thread.attachment,
               let thumbURL = attachment.thumbnailURL(boardID: board.id) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.08))
                        .frame(height: 150)
                        .offset(x: -8, y: -8)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.14))
                        .frame(height: 150)
                        .offset(x: -4, y: -4)
                    RemoteImageView(url: thumbURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Label("\(thread.imageCount)", systemImage: "photo")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(8)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : .secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.2)
        )
    }
}

#Preview("Thread List") {
    NavigationStack {
        ThreadListView(board: Board(id: "g", title: "Technology", isWorksafe: true))
    }
}
#endif
