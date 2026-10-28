import AppKit
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
        let clock = DayClock(defaults: defaults, startsTimer: false)
        clock.cardStyle = .dark
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
