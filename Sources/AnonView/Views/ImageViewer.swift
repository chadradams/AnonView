#if canImport(SwiftUI)
import SwiftUI
import ImageIO
#if canImport(AVKit)
import AVKit
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ImageViewer: View {
    let attachments: [ImageAttachment]
    let boardID: String
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var zoom: CGFloat = 1
    @State private var thumbnailImage: Image?
    @State private var fullImageData: Data?
    @State private var videoPlayer: AVPlayer?
    @State private var currentIndex = 0
    @State private var loadFailed = false

    private let imageLoader = ImageLoader()

    private var currentAttachment: ImageAttachment? {
        guard attachments.indices.contains(currentIndex) else { return nil }
        return attachments[currentIndex]
    }
    private var imageCountLabel: String {
        attachments.isEmpty ? "0/0" : "\(currentIndex + 1)/\(attachments.count)"
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if attachments.isEmpty {
                Text("No images available")
                    .foregroundStyle(.white)
            } else if let attachment = currentAttachment {
                if attachment.isVideo {
                    videoView(for: attachment)
                } else if let data = fullImageData {
                    fullMediaView(data: data, mediaType: attachment.mediaType)
                } else if let thumb = thumbnailImage {
                    thumb
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .center) {
                            ProgressView()
                                .tint(.white)
                        }
                } else if loadFailed {
                    Text("Unable to load image")
                        .foregroundStyle(.white)
                } else {
                    ProgressView()
                        .tint(.white)
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
            if attachments.isEmpty {
                loadFailed = true
                AppLogger.error("Image viewer opened with no images")
                return
            }
            currentIndex = max(0, min(initialIndex, attachments.count - 1))
            AppLogger.info("Image viewer opened with \(attachments.count) images, starting at \(currentIndex)")
        }
        .task(id: currentIndex) {
            guard let attachment = currentAttachment else { return }
            thumbnailImage = nil
            fullImageData = nil
            videoPlayer = nil
            loadFailed = false
            zoom = 1

            // Load the JPEG thumbnail immediately so something is visible right away.
            if let thumbURL = attachment.thumbnailURL(boardID: boardID),
               let thumbData = try? await imageLoader.loadImageData(url: thumbURL) {
                thumbnailImage = thumbData.platformImage.map(Image.init)
            }

            // Videos cannot be decoded as images; the thumbnail + play overlay is enough.
            if attachment.isVideo {
                if let mediaURL = attachment.imageURL(boardID: boardID) {
                    videoPlayer = AVPlayer(url: mediaURL)
                }
                return
            }

            guard let fullURL = attachment.imageURL(boardID: boardID) else {
                loadFailed = true
                return
            }

            do {
                let data = try await imageLoader.loadImageData(url: fullURL)
                // Verify the data is decodable for static images; GIF data is accepted as-is.
                if attachment.mediaType == .image && PlatformImage(data: data) == nil {
                    AppLogger.error("Unsupported image format: \(fullURL.lastPathComponent)")
                    loadFailed = true
                } else {
                    fullImageData = data
                }
            } catch {
                AppLogger.error("Failed to load image \(fullURL.absoluteString): \(error.localizedDescription)")
                loadFailed = true
            }

            // Prefetch adjacent non-video items so navigation feels instant.
            let adjacent = [-1, 1, 2].compactMap { offset -> URL? in
                let idx = currentIndex + offset
                guard attachments.indices.contains(idx),
                      !attachments[idx].isVideo else { return nil }
                return attachments[idx].imageURL(boardID: boardID)
            }
            imageLoader.prefetch(urls: adjacent)
        }
        .onDisappear {
            videoPlayer?.pause()
        }
    }

    // MARK: - Sub-views

    private var videoPlayIcon: some View {
        Image(systemName: "play.circle.fill")
            .font(.system(size: 72))
            .foregroundStyle(.white.opacity(0.85))
            .shadow(radius: 8)
    }

    @ViewBuilder
    private func videoView(for attachment: ImageAttachment) -> some View {
        ZStack {
            #if canImport(AVKit)
            if let videoPlayer {
                VideoPlayer(player: videoPlayer)
                    .scaledToFit()
            }
            #endif

            if videoPlayer == nil, let thumb = thumbnailImage {
                thumb
                    .resizable()
                    .scaledToFit()
            }

            if videoPlayer == nil {
                videoPlayIcon
            }
        }
    }

    @ViewBuilder
    private func fullMediaView(data: Data, mediaType: ImageAttachment.MediaType) -> some View {
        #if canImport(UIKit)
        if mediaType == .animatedGIF {
            AnimatedGIFView(data: data)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(zoom)
                .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
        } else if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoom)
                .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
        } else {
            Text("Unable to load image").foregroundStyle(.white)
        }
        #elseif canImport(AppKit)
        if mediaType == .animatedGIF {
            AnimatedGIFView(data: data)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(zoom)
                .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
        } else if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoom)
                .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
        } else {
            Text("Unable to load image").foregroundStyle(.white)
        }
        #endif
    }

    // MARK: - Navigation helpers

    private var canMoveNext: Bool { currentIndex < attachments.count - 1 }
    private var canMovePrevious: Bool { currentIndex > 0 }

    private func moveToNextImage() {
        guard canMoveNext else { return }
        currentIndex += 1
    }

    private func moveToPreviousImage() {
        guard canMovePrevious else { return }
        currentIndex -= 1
    }
}

// MARK: - Animated GIF helper views

/// Plays an animated GIF using the platform's native image view.
/// Falls back to showing the first frame when the data contains only one frame.
#if canImport(UIKit)
private struct AnimatedGIFView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.image = Self.animatedImage(from: data) ?? UIImage(data: data)
    }

    /// Decodes all GIF frames via ImageIO and assembles an animated UIImage.
    private static func animatedImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }

        let defaultFrameDelay = 0.1
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifProps?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gifProps?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? defaultFrameDelay
            totalDuration += max(delay, 0.01)
        }

        return frames.isEmpty ? nil : UIImage.animatedImage(with: frames, duration: totalDuration)
    }
}
#elseif canImport(AppKit)
private struct AnimatedGIFView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.image = NSImage(data: data)
    }
}
#endif

// MARK: - Platform image helper

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

#Preview("Image Viewer") {
    ImageViewer(
        attachments: [ImageAttachment(tim: 1700000000000, ext: ".jpg")],
        boardID: "g",
        initialIndex: 0
    )
}

#endif
