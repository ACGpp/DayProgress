import AppKit
import SwiftUI

@MainActor
final class Probe: NSObject, NSApplicationDelegate {
    static var date = Date(timeIntervalSince1970: 1_798_718_400)
    static let suite = "DayProgress.memory-probe.\(ProcessInfo.processInfo.processIdentifier)"
    static let clock = DayClock(defaults: UserDefaults(suiteName: suite)!, dateProvider: { date }, startsTimer: false)
    private var timer: Timer?
    private var window: NSWindow?
    private var ticks = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Probe.clock.mode = .custom
        Probe.clock.customStartMinutes = 480
        Probe.clock.customEndMinutes = 60
        let hosting = NSHostingView(rootView: PopoverView(clock: Probe.clock, startsOnSettings: true))
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 372, height: 700),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "DayProgress isolated performance probe"
        window.contentView = hosting
        window.orderFrontRegardless()
        self.window = window
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.ticks += 1
                Probe.date = Probe.date.addingTimeInterval(10)
                Probe.clock.refresh()
                if self.ticks == 1200 {
                    self.timer?.invalidate()
                    if let path = ProcessInfo.processInfo.environment["PROBE_READY"] {
                        FileManager.default.createFile(atPath: path, contents: Data("1200".utf8))
                    }
                    UserDefaults.standard.removePersistentDomain(forName: Probe.suite)
                }
            }
        }
    }
}

@main
struct MemoryProbe: App {
    @NSApplicationDelegateAdaptor(Probe.self) private var delegate
#if LEGACY_SCENE
    @StateObject private var clock = Probe.clock
#else
    private let clock = Probe.clock
#endif
    var body: some Scene {
        MenuBarExtra {
            Text("Isolated DayProgress memory probe")
        } label: {
#if LEGACY_SCENE
            Text(clock.percentText)
                .accessibilityLabel("\(clock.displayCaption) \(clock.percentText)")
#else
            MenuBarLabel(clock: clock)
#endif
        }
        .menuBarExtraStyle(.window)
    }
}
