#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ImageViewer: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var zoom: CGFloat = 1
    @State private var image: Image?

    private let imageLoader = ImageLoader()
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoom)
                        .gesture(MagnificationGesture().onChanged { zoom = min(max($0, 1), 4) })
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .navigation) {
#else
                ToolbarItem(placement: .topBarLeading) {
#endif
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            do {
                let data = try await imageLoader.loadImageData(url: imageURL)
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
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
private typealias PlatformImage = NSImage
#endif

#endif
