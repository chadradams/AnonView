#if canImport(SwiftUI)
import SwiftUI

public struct ThreadDetailView: View {
    private let board: Board
    private let threadID: Int
    @StateObject private var viewModel: ThreadViewModel
    @State private var selectedImageIndex: Int?
    @State private var scrollTargetPostID: Int?

    private let nsfwFilter = NSFWFilterService()
    private var isImageViewerPresented: Binding<Bool> {
        Binding(
            get: { selectedImageIndex != nil },
            set: { if !$0 { selectedImageIndex = nil } }
        )
    }
    private var imageURLs: [URL] {
        viewModel.posts.compactMap { $0.attachment?.imageURL(boardID: board.id) }
    }

    public init(board: Board, threadID: Int) {
        self.board = board
        self.threadID = threadID
        _viewModel = StateObject(wrappedValue: ThreadViewModel(boardID: board.id, threadID: threadID))
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.posts) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(post.author ?? "Anonymous")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                if let originalURL = URL(string: "https://boards.4chan.org/\(board.id)/thread/\(threadID)#p\(post.id)") {
                                    Link(destination: originalURL) {
                                        Text("Original")
                                            .font(.caption.weight(.semibold))
                                    }
                                }
                                Text(Date(timeIntervalSince1970: post.timestamp), style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("#\(post.id)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let comment = post.comment, !comment.isEmpty {
                                if let parsed = try? AttributedString(markdown: comment.commentMarkdown) {
                                    Text(parsed)
                                        .font(.body)
                                } else {
                                    Text(comment.lightlyParsedHTML)
                                        .font(.body)
                                }
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
                                        selectedImageIndex = imageURLs.firstIndex(of: fullURL)
                                    }
                            }

                            Divider()
                        }
                        .id(post.id)
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 10)
            }
            .onChange(of: scrollTargetPostID) { _, targetID in
                guard let targetID else { return }
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .center)
                }
            }
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
        .environment(\.openURL, OpenURLAction { url in
            if let postID = postIDToScroll(for: url) {
                AppLogger.info("Navigating to linked post #\(postID)")
                scrollTargetPostID = postID
                return .handled
            }
            return .systemAction(url)
        })
#if os(macOS)
        .sheet(isPresented: isImageViewerPresented) {
            if let selectedImageIndex {
                ImageViewer(imageURLs: imageURLs, initialIndex: selectedImageIndex)
            }
        }
#else
        .fullScreenCover(isPresented: isImageViewerPresented) {
            if let selectedImageIndex {
                ImageViewer(imageURLs: imageURLs, initialIndex: selectedImageIndex)
            }
        }
#endif
    }

    private func postIDToScroll(for url: URL) -> Int? {
        if url.scheme == "anonview",
           url.host == "post",
           let id = Int(url.lastPathComponent) {
            return id
        }

        let fragment = url.fragment ?? ""
        if fragment.hasPrefix("p"), let id = Int(fragment.dropFirst()) {
            return id
        }

        return nil
    }
}
#endif
