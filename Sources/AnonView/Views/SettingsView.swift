#if canImport(SwiftUI)
import SwiftUI

public struct SettingsView: View {
    @State private var blurNSFW = NSFWFilterService().blurNSFWImages
    private let filterService = NSFWFilterService()
    private let cacheManager: CacheManager

    public init(cacheManager: CacheManager = .shared) {
        self.cacheManager = cacheManager
    }

    public var body: some View {
        Form {
            Toggle("Blur NSFW Images", isOn: $blurNSFW)
                .onChange(of: blurNSFW) { _, newValue in
                    filterService.blurNSFWImages = newValue
                }

            Button(role: .destructive) {
                try? cacheManager.clear()
            } label: {
                Label("Clear Cache", systemImage: "trash")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}
#endif
