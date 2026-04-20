# AnonView

A 4chan app for iOS and macOS.

## Local setup

### Requirements
- Xcode 16+ (for running the app on iOS/macOS)
- Swift 6.1+ toolchain (for command-line build/test)

### Run locally (Xcode)
1. Open `/home/runner/work/AnonView/AnonView/AnonView.xcodeproj` in Xcode.
2. Choose either `AnonView iOS` (simulator/device) or `AnonView macOS`.
3. Run the selected app target.

### CLI build with Xcode project (macOS host)
```bash
xcodebuild -project AnonView.xcodeproj -scheme "AnonView iOS" -destination "generic/platform=iOS" build
xcodebuild -project AnonView.xcodeproj -scheme "AnonView macOS" -destination "generic/platform=macOS" build
```

### Build and test locally (CLI)
From `/home/runner/work/AnonView/AnonView`:

```bash
swift build
swift test
```

## Configuration

- No API keys or environment variables are required.
- The app uses the public 4chan JSON API (`https://a.4cdn.org`), so outbound network access is required.
- NSFW image blurring is enabled by default and can be toggled in **Settings → Blur NSFW Images**.
- Cached data can be cleared in **Settings → Clear Cache**.
