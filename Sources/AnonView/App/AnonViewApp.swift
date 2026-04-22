#if canImport(SwiftUI)
import SwiftUI

@main
public struct AnonViewApp: App {
    // Run cleanup only after meaningful inactivity to avoid unnecessary churn.
    private static let minimumBackgroundDurationForCacheCleanup: TimeInterval = 900 // 15 minutes

    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedBoard: Board?
    @State private var selectedThread: ThreadSummary?
    @State private var backgroundedAt: Date?
    private let cacheManager = CacheManager.shared

    public init() {}

    public var body: some Scene {
        WindowGroup {
            Group {
                #if os(iOS)
                IOSRootView()
                #else
                SplitRootView(selectedBoard: $selectedBoard, selectedThread: $selectedThread)
                #endif
            }
            .onAppear {
                cacheManager.clearMemoryCache()
                cacheManager.removeExpiredEntries()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    backgroundedAt = Date()
                case .active:
                    if let backgroundedAt,
                       Date().timeIntervalSince(backgroundedAt) >= Self.minimumBackgroundDurationForCacheCleanup {
                        cacheManager.clearMemoryCache()
                        cacheManager.removeExpiredEntries()
                    }
                    self.backgroundedAt = nil
                default:
                    break
                }
            }
        }
        #if os(macOS)
        Settings {
            NavigationStack { SettingsView() }
                .frame(minWidth: 520, minHeight: 360)
        }
        #endif
    }
}

private struct SplitRootView: View {
    @Binding var selectedBoard: Board?
    @Binding var selectedThread: ThreadSummary?

    var body: some View {
        NavigationSplitView {
            BoardListView(selection: $selectedBoard)
        } content: {
            if let selectedBoard {
                ThreadListView(board: selectedBoard, selection: $selectedThread)
                    .id(selectedBoard.id)
            } else {
                ContentUnavailableView("Select a Board", systemImage: "list.bullet.rectangle")
            }
        } detail: {
            if let selectedBoard, let selectedThread {
                ThreadDetailView(board: selectedBoard, threadID: selectedThread.id)
            } else {
                ContentUnavailableView("Select a Thread", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .onChange(of: selectedBoard) { _, _ in
            selectedThread = nil
        }
    }
}

#if os(iOS)
private struct IOSRootView: View {
    var body: some View {
        NavigationStack {
            BoardListView()
                .navigationDestination(for: Board.self) { board in
                    ThreadListView(board: board)
                        .navigationDestination(for: ThreadSummary.self) { thread in
                            ThreadDetailView(board: board, threadID: thread.id)
                        }
                }
                .toolbar {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
        }
    }
}
#endif
#endif
