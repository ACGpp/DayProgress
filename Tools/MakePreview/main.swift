import AppKit
import SwiftUI

@main
struct PreviewRenderer {
    static func main() {
        MainActor.assumeIsolated {
            renderAll()
        }
    }

    @MainActor
    private static func renderAll() {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)

        let suiteName = "dayprogress.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 28
        components.hour = 18
        components.minute = 9
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let fixedDate = calendar.date(from: components)!
        let clock = DayClock(defaults: defaults, dateProvider: { fixedDate }, startsTimer: false)

        clock.timeZoneID = "Asia/Shanghai"
        clock.cardStyle = .dark
        clock.progressMode = .elapsed

        for language in Language.allCases {
            clock.language = language
            clock.cardSize = .large
            render(desktopScene(clock: clock), scale: 2, name: "card-large-\(language.rawValue).png")
        }

        clock.language = .chinese
        for size in CardSize.allCases where size != .large {
            clock.cardSize = size
            render(desktopScene(clock: clock), scale: 2, name: "card-\(size.rawValue).png")
        }

        clock.cardSize = .large
        clock.cardStyle = .plain
        render(desktopScene(clock: clock), scale: 2, name: "card-plain.png")

        clock.cardStyle = .glass
        render(desktopScene(clock: clock), scale: 2, name: "card-glass.png")

        clock.cardStyle = .dark
        clock.progressMode = .remaining
        render(desktopScene(clock: clock), scale: 2, name: "card-remaining.png")
        clock.progressMode = .elapsed

        render(popoverPreview(clock: clock, dark: false), scale: 2, name: "popover-light.png")
        render(popoverPreview(clock: clock, dark: true), scale: 2, name: "popover-dark.png")
        clock.language = .english
        render(popoverPreview(clock: clock, dark: false), scale: 2, name: "popover-en.png")
        clock.language = .chinese
        clock.mode = .custom
        clock.customStartMinutes = 7 * 60
        clock.customEndMinutes = 23 * 60
        render(popoverPreview(clock: clock, dark: false, settings: true), scale: 2, name: "popover-settings.png")
        clock.showFloatingCard = false
        render(popoverPreview(clock: clock, dark: false, settings: true), scale: 2, name: "popover-menu-only.png")
        render(iconArtwork, scale: 1, name: "AppIcon.png", directory: "build")
    }

    @MainActor
    private static func desktopScene(clock: DayClock) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.45, blue: 0.60),
                    Color(red: 0.14, green: 0.18, blue: 0.28),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            ZStack {
                if clock.cardStyle == .glass {
                    RoundedRectangle(cornerRadius: clock.cardSize.cornerRadius)
                        .fill(.ultraThinMaterial)
                        .frame(width: clock.cardSize.size.width, height: clock.cardSize.size.height)
                }
                FloatingCardView(clock: clock)
            }
        }
        .frame(width: 440, height: 240)
        .environment(\.colorScheme, .dark)
    }

    @MainActor
    private static func popoverPreview(clock: DayClock, dark: Bool, settings: Bool = false) -> some View {
        PopoverView(clock: clock, startsOnSettings: settings)
            .frame(width: 336)
            .fixedSize(horizontal: true, vertical: true)
            .background(dark ? Color(red: 0.14, green: 0.14, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.96))
            .environment(\.colorScheme, dark ? .dark : .light)
            .padding(24)
            .background(dark ? Color(red: 0.06, green: 0.06, blue: 0.07) : Color(red: 0.86, green: 0.87, blue: 0.89))
    }

    private static var iconArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 210, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.15, blue: 0.20),
                            Color(red: 0.05, green: 0.06, blue: 0.09),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 210, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 3)
                )
                .padding(96)

            SegmentedDayRing(progress: 0.79, lineWidth: 64, slots: 24)
                .frame(width: 600, height: 600)

            VStack(spacing: 4) {
                Text("79%")
                    .font(.system(size: 168, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("DAY")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .tracking(16)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .offset(y: -12)
        }
        .frame(width: 1024, height: 1024)
        .environment(\.colorScheme, .dark)
    }

    @MainActor
    private static func render<V: View>(_ view: V,
                                        scale: CGFloat,
                                        name: String,
                                        directory: String = "build/preview") {
        // NSHostingView also renders AppKit-backed controls (Picker, Toggle).
        let hosting = NSHostingView(rootView: view)
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
            fatalError("Cannot allocate preview: \(name)")
        }
        bitmap.size = size
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Cannot encode preview: \(name)")
        }
        let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let url = directoryURL.appendingPathComponent(name)
        do {
            try png.write(to: url)
            print("wrote \(url.path)")
        } catch {
            print("write failed: \(name): \(error)")
        }
    }
}
