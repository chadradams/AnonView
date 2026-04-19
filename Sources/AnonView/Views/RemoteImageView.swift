#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct RemoteImageView: View {
    private let url: URL
    private let imageLoader: ImageLoader

    @State private var image: Image?

    public init(url: URL, imageLoader: ImageLoader = ImageLoader()) {
        self.url = url
        self.imageLoader = imageLoader
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))

            if let image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let data = try await imageLoader.loadImageData(url: url)
                image = data.platformImage.map(Image.init)
            } catch {
                image = nil
            }
        }
    }
}

private extension Data {
    var platformImage: PlatformImage? {
        PlatformImage(data: self)
    }
}

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif
#endif
