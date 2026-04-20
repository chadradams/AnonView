#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if imageURLs.isEmpty {
                Text("No images available")
                    .foregroundStyle(.white)
            } else if let image {
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
            currentIndex = min(max(initialIndex, 0), max(imageURLs.count - 1, 0))
            AppLogger.info("Image viewer opened with \(imageURLs.count) images, starting at \(currentIndex)")
        }
        .task(id: currentURL) {
            guard let currentURL else { return }
            loadFailed = false
            zoom = 1

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

#endif
