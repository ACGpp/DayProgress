import Foundation

@main
struct ClockTests {
    @MainActor
    static func main() {
        let suite = "DayProgress.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
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
        print("Clock boundary, precision, timezone and localization checks passed")
    }
}
