# AnonView

A 4chan app for iOS and macOS.

## Local setup

### Requirements
- Xcode 16+ (for running the app on iOS/macOS)
- Swift 6.1+ toolchain (for command-line build/test)

### Run locally (Xcode)
1. Open `/home/runner/work/AnonView/AnonView/Package.swift` in Xcode.
2. Choose an iOS Simulator or a macOS target.
3. Run the `AnonView` app target.

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
