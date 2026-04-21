#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(WebKit)
import WebKit
#endif

private enum MediaKind {
    case staticImage
    case webImage
    case video

    init(url: URL) {
        let ext = url.pathExtension.lowercased()
        if Self.videoExtensions.contains(ext) {
            self = .video
        } else if Self.webImageExtensions.contains(ext) {
            self = .webImage
        } else {
            self = .staticImage
        }
    }

    private static let webImageExtensions: Set<String> = ["gif", "webp"]
    private static let videoExtensions: Set<String> = ["mp4", "m4v", "mov", "webm", "ogg", "ogv"]
}

public struct ImageViewer: View {
    let imageURLs: [URL]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var zoom: CGFloat = 1
    @State private var image: Image?
    @State private var currentIndex = 0
    @State private var loadFailed = false

    private let imageLoader = ImageLoader()
    private var currentURL: URL? {
        guard imageURLs.indices.contains(currentIndex) else { return nil }
        return imageURLs[currentIndex]
    }
    private var imageCountLabel: String {
        imageURLs.isEmpty ? "0/0" : "\(currentIndex + 1)/\(imageURLs.count)"
    }
    private var currentMediaKind: MediaKind {
        guard let currentURL else { return .staticImage }
        return MediaKind(url: currentURL)
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if imageURLs.isEmpty {
                Text("No images available")
                    .foregroundStyle(.white)
            } else {
                switch currentMediaKind {
                case .staticImage:
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(zoom)
                            .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
                    } else if loadFailed {
                        Text("Unable to load image")
                            .foregroundStyle(.white)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                case .webImage, .video:
                    if let currentURL {
                        WebMediaView(url: currentURL, mediaKind: currentMediaKind)
                    } else {
                        Text("Unable to load media")
                            .foregroundStyle(.white)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer()

                HStack {
                    Button {
                        moveToPreviousImage()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(canMovePrevious ? .white.opacity(0.9) : .white.opacity(0.35))
                    .disabled(!canMovePrevious)

                    Spacer()

                    Text(imageCountLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.5), in: Capsule())

                    Spacer()

                    Button {
                        moveToNextImage()
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(canMoveNext ? .white.opacity(0.9) : .white.opacity(0.35))
                    .disabled(!canMoveNext)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width <= -60 {
                        moveToNextImage()
                    } else if value.translation.width >= 60 {
                        moveToPreviousImage()
                    }
                }
        )
        .onAppear {
            if imageURLs.isEmpty {
                loadFailed = true
                image = nil
                AppLogger.error("Image viewer opened with no images")
                return
            }
            currentIndex = max(0, min(initialIndex, imageURLs.count - 1))
            AppLogger.info("Image viewer opened with \(imageURLs.count) images, starting at \(currentIndex)")
        }
        .task(id: currentURL) {
            guard let currentURL else { return }
            loadFailed = false
            zoom = 1
            let mediaKind = MediaKind(url: currentURL)
            guard mediaKind == .staticImage else {
                image = nil
                return
            }

            do {
                let data = try await imageLoader.loadImageData(url: currentURL)
                image = data.platformImage.map(Image.init)
                loadFailed = image == nil
            } catch {
                AppLogger.error("Failed to load image \(currentURL.absoluteString): \(error.localizedDescription)")
                image = nil
                loadFailed = true
            }
        }
    }

    private var canMoveNext: Bool {
        currentIndex < imageURLs.count - 1
    }

    private var canMovePrevious: Bool {
        currentIndex > 0
    }

    private func moveToNextImage() {
        guard canMoveNext else { return }
        currentIndex += 1
    }

    private func moveToPreviousImage() {
        guard canMovePrevious else { return }
        currentIndex -= 1
    }
}

#Preview("Image Viewer") {
    ImageViewer(
        imageURLs: [URL(string: "https://i.4cdn.org/g/1700000000000.jpg")!],
        initialIndex: 0
    )
}

private extension Data {
    var platformImage: PlatformImage? {
        PlatformImage(data: self)
    }
}

#if canImport(UIKit)
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
private typealias PlatformImage = NSImage
#endif

#if canImport(WebKit)
private struct WebMediaView: View {
    let url: URL
    let mediaKind: MediaKind

    var body: some View {
        PlatformWebView(html: html)
    }

    private var html: String {
        let source = url.absoluteString.htmlEscaped
        let content: String
        switch mediaKind {
        case .video:
            content = """
            <video controls autoplay loop playsinline>
              <source src="\(source)">
            </video>
            """
        case .webImage, .staticImage:
            content = "<img src=\"\(source)\" alt=\"Media\" />"
        }

        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: black; overflow: hidden; }
            body { display: flex; align-items: center; justify-content: center; }
            img, video { width: 100%; height: 100%; object-fit: contain; background: black; }
          </style>
        </head>
        <body>
          \(content)
        </body>
        </html>
        """
    }
}

#if canImport(UIKit)
private struct PlatformWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
#elseif canImport(AppKit)
private struct PlatformWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
#endif
#else
private struct WebMediaView: View {
    let url: URL
    let mediaKind: MediaKind

    var body: some View {
        Text("Unsupported media format")
            .foregroundStyle(.white)
    }
}
#endif

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

#endif
