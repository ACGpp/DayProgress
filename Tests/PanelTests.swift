import AppKit
import Combine
import SwiftUI

@main
struct PanelTests {
    @MainActor
    static func main() async {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let suite = "DayProgress.panel-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var date = Date(timeIntervalSince1970: 1_798_718_400)
        let clock = DayClock(defaults: defaults, dateProvider: { date }, startsTimer: false)
        clock.cardStyle = .dark
        let popover = PopoverClockModel(clock: clock, showingSettings: true)
        var updates = 0
        let subscription = popover.objectWillChange.sink { updates += 1 }
        date = date.addingTimeInterval(10)
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(updates == 0, "Settings controls must not refresh on an ordinary tick")
        clock.language = clock.language == .english ? .chinese : .english
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(updates == 1, "Settings changes must still reach controls")
        // Crossing a DST boundary must refresh the offsets in the timezone picker.
        date = ISO8601DateFormatter().date(from: "2026-03-08T06:59:50Z")!
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        let beforeDST = updates
        date = date.addingTimeInterval(20)
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(updates == beforeDST + 1)
        popover.showingSettings = false
        let beforeTick = updates
        date = date.addingTimeInterval(10)
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(updates == beforeTick + 1, "Main page must retain precise progress updates")
        withExtendedLifetime(subscription) {}
        let delegate = AppDelegate(clock: clock, defaults: defaults)
        assert(delegate.panel == nil, "Hidden card must not allocate a window")
        for _ in 0..<100 {
            delegate.setPanelVisible(true)
            assert(delegate.panel != nil)
            weak var oldContent: NSView?
            oldContent = delegate.panel?.contentView
            assert(oldContent?.subviews.contains(where: { $0 is NSVisualEffectView }) == false)
            delegate.apply(cardStyle: .glass)
            weak var oldEffect: NSView?
            oldEffect = oldContent?.subviews.first(where: { $0 is NSVisualEffectView })
            assert(oldEffect != nil)
            delegate.apply(cardStyle: .dark)
            delegate.setPanelVisible(false)
            try! await Task.sleep(nanoseconds: 10_000_000)
            assert(delegate.panel == nil)
            assert(oldContent == nil, "Hidden card must release its view tree")
            assert(oldEffect == nil, "Leaving glass must release the visual effect")
        }
        assert(defaults.object(forKey: DayClock.Key.floatingTopRightX) != nil)
        delegate.setPanelVisible(true)
        assert(delegate.panel?.frame.size == clock.cardSize.size)
        delegate.setPanelVisible(false)
        print("100 panel show/hide and glass/dark lifecycle checks passed")
    }
}
