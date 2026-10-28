import Foundation
import Combine

@main
struct ClockTests {
    @MainActor
    static func main() async {
        let suite = "DayProgress.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var date = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
        let clock = DayClock(defaults: defaults, dateProvider: { date }, startsTimer: false)
        clock.timeZoneID = "UTC"
        clock.language = .english
        assert(clock.progress == 0.5)
        assert(clock.percentText == "50.0%")
        clock.progressMode = .remaining
        assert(clock.percentText == "50.0%")
        clock.percentPrecision = .integer
        assert(clock.percentText == "50%")
        clock.mode = .custom
        clock.customStartMinutes = 8 * 60
        clock.customEndMinutes = 12 * 60
        assert(clock.isWindowComplete)
        assert(clock.percentText == "0%")
        assert(clock.windowTitle.contains("08:00"))
        clock.timeZoneID = "Asia/Shanghai"
        assert(clock.todayTitle.contains("Oct"))
        clock.language = .chinese
        assert(clock.todayTitle.contains("10月"))
        clock.mode = .natural
        clock.timeZoneID = "UTC"
        clock.progressMode = .elapsed
        clock.percentPrecision = .decimal
        let model = MenuBarDisplayModel(clock: clock)
        var publications = 0
        let subscription = model.$display.dropFirst().sink { _ in publications += 1 }
        date = date.addingTimeInterval(10)
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(publications == 0, "Unchanged menu text must not publish")
        date = date.addingTimeInterval(80)
        clock.refresh()
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(model.display.percent == "50.1%")
        assert(publications == 1)
        clock.language = .english
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(model.display.caption == "Today elapsed")
        assert(publications == 2, "Accessibility caption must update with language")
        clock.timeZoneID = "Asia/Shanghai"
        try! await Task.sleep(nanoseconds: 50_000_000)
        assert(model.display.percent == clock.percentText)
        assert(clock.todayTitle.contains("Oct"))
        withExtendedLifetime(subscription) {}
        weak var released: MenuBarDisplayModel?
        do {
            let transient = MenuBarDisplayModel(clock: clock)
            released = transient
        }
        assert(released == nil, "Clock subscription must not retain its display model")
        print("Clock boundary, precision, timezone and localization checks passed")
    }
}
