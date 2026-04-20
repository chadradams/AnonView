#if canImport(SwiftUI)
import SwiftUI

@main
public struct AnonViewApp: App {
    @State private var selectedBoard: Board?
    @State private var selectedThread: ThreadSummary?

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
        }
        #if os(macOS)
        Settings {
            NavigationStack { SettingsView() }
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
