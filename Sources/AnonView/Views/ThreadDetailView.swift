#if canImport(SwiftUI)
import SwiftUI

public struct ThreadDetailView: View {
    private let board: Board
    private let threadID: Int
    @StateObject private var viewModel: ThreadViewModel
    @State private var selectedImageURL: URL?

    private let nsfwFilter = NSFWFilterService()
    private var isImageViewerPresented: Binding<Bool> {
        Binding(
            get: { selectedImageURL != nil },
            set: { if !$0 { selectedImageURL = nil } }
        )
    }

    public init(board: Board, threadID: Int) {
        self.board = board
        self.threadID = threadID
        _viewModel = StateObject(wrappedValue: ThreadViewModel(boardID: board.id, threadID: threadID))
    }

    public var body: some View {
        List(viewModel.posts) { post in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(post.author ?? "Anonymous")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(Date(timeIntervalSince1970: post.timestamp), style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("#\(post.id)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                if let comment = post.comment, !comment.isEmpty {
                    Text(comment.lightlyParsedHTML)
                        .font(.body)
                }

                if let attachment = post.attachment,
                   let thumbURL = attachment.thumbnailURL(boardID: board.id),
                   let fullURL = attachment.imageURL(boardID: board.id) {
                    let shouldBlur = nsfwFilter.blurNSFWImages &&
                        nsfwFilter.isNSFW(boardID: board.id, boardIsWorksafe: board.isWorksafe, spoiler: post.spoiler, subject: post.subject)

                    RemoteImageView(url: thumbURL)
                        .frame(maxWidth: 240, minHeight: 120, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .blur(radius: shouldBlur ? 14 : 0)
                        .overlay {
                            if shouldBlur {
                                Text("Tap to reveal")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(.black.opacity(0.65), in: Capsule())
                            }
                        }
                        .onTapGesture {
                            selectedImageURL = fullURL
                        }
                }
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Thread")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "exclamationmark.triangle")
            }
        }
        .task { await viewModel.loadPosts() }
        .refreshable { await viewModel.loadPosts(forceRefresh: true) }
#if os(macOS)
        .sheet(isPresented: isImageViewerPresented) {
#else
        .fullScreenCover(isPresented: isImageViewerPresented) {
#endif
            if let url = selectedImageURL {
                ImageViewer(imageURL: url)
            }
        }
    }
}
#endif
