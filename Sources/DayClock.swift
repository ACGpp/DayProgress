import Combine
import CoreGraphics
import Foundation

/// 一天的计时方式：自然日（00:00–24:00）或自定义时段。
enum DayMode: String, CaseIterable, Identifiable {
    case natural
    case custom

    var id: String { rawValue }

    func title(_ language: Language) -> String {
        switch (self, language) {
        case (.natural, .chinese): return "自然日"
        case (.custom, .chinese): return "自定义"
        case (.natural, .english): return "Natural"
        case (.custom, .english): return "Custom"
        }
    }
}

/// 桌面浮窗尺寸。
enum CardSize: String, CaseIterable, Identifiable {
    case large
    case medium
    case mini

    var id: String { rawValue }

    func title(_ language: Language) -> String {
        switch (self, language) {
        case (.large, .chinese): return "大"
        case (.medium, .chinese): return "中"
        case (.mini, .chinese): return "小"
        case (.large, .english): return "Large"
        case (.medium, .english): return "Medium"
        case (.mini, .english): return "Small"
        }
    }

    var size: CGSize {
        switch self {
        case .large: return CGSize(width: 268, height: 114)
        case .medium: return CGSize(width: 188, height: 72)
        case .mini: return CGSize(width: 92, height: 92)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .large: return 24
        case .medium: return 18
        case .mini: return 26
        }
    }
}

/// 桌面浮窗外观。
enum CardStyle: String, CaseIterable, Identifiable {
    case dark
    case glass
    case plain

    var id: String { rawValue }

    func title(_ language: Language) -> String {
        switch (self, language) {
        case (.dark, .chinese): return "深色"
        case (.glass, .chinese): return "毛玻璃"
        case (.plain, .chinese): return "透明"
        case (.dark, .english): return "Dark"
        case (.glass, .english): return "Glass"
        case (.plain, .english): return "Clear"
        }
    }
}

struct DayWindow {
    let start: Date
    let end: Date

    var duration: TimeInterval { max(1, end.timeIntervalSince(start)) }
}

/// 全局时钟：每 10 秒刷新一次，对外提供“今天过半了多少”的各种派生值。
@MainActor
final class DayClock: ObservableObject {
    static let shared = DayClock()

    enum Key {
        static let mode = "dayMode"
        static let customStart = "customStartMinutes"
        static let customEnd = "customEndMinutes"
        static let showFloatingCard = "showFloatingCard"
        static let cardSize = "cardSize"
        static let cardStyle = "cardStyle"
        static let language = "language"
        static let progressMode = "progressMode"
        static let percentPrecision = "percentPrecision"
        static let timeZoneID = "timeZoneID"
        static let floatingX = "floatingX"
        static let floatingY = "floatingY"
        static let floatingTopRightX = "floatingTopRightX"
        static let floatingTopRightY = "floatingTopRightY"
    }

    @Published private(set) var now: Date
    @Published var mode: DayMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }
    @Published var customStartMinutes: Int {
        didSet { defaults.set(customStartMinutes, forKey: Key.customStart) }
    }
    @Published var customEndMinutes: Int {
        didSet { defaults.set(customEndMinutes, forKey: Key.customEnd) }
    }
    @Published var showFloatingCard: Bool {
        didSet { defaults.set(showFloatingCard, forKey: Key.showFloatingCard) }
    }
    @Published var cardSize: CardSize {
        didSet { defaults.set(cardSize.rawValue, forKey: Key.cardSize) }
    }
    @Published var cardStyle: CardStyle {
        didSet { defaults.set(cardStyle.rawValue, forKey: Key.cardStyle) }
    }
    @Published var language: Language {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }
    @Published var progressMode: ProgressMode {
        didSet { defaults.set(progressMode.rawValue, forKey: Key.progressMode) }
    }
    @Published var percentPrecision: PercentPrecision {
        didSet { defaults.set(percentPrecision.rawValue, forKey: Key.percentPrecision) }
    }
    @Published var timeZoneID: String {
        didSet { defaults.set(timeZoneID, forKey: Key.timeZoneID) }
    }

    private let defaults: UserDefaults
    private let dateProvider: () -> Date
    private var timer: Timer?

    init(defaults: UserDefaults = .standard,
         dateProvider: @escaping () -> Date = { Date() },
         startsTimer: Bool = true) {
        self.defaults = defaults
        self.dateProvider = dateProvider
        defaults.register(defaults: [
            Key.mode: DayMode.natural.rawValue,
            Key.customStart: 7 * 60,
            Key.customEnd: 23 * 60,
            Key.showFloatingCard: true,
            Key.cardSize: CardSize.large.rawValue,
            Key.cardStyle: CardStyle.dark.rawValue,
            Key.language: Language.chinese.rawValue,
            Key.progressMode: ProgressMode.elapsed.rawValue,
            Key.percentPrecision: PercentPrecision.decimal.rawValue,
            Key.timeZoneID: TimeZoneOption.systemID,
        ])
        self.now = dateProvider()
        self.mode = DayMode(rawValue: defaults.string(forKey: Key.mode) ?? "") ?? .natural
        self.customStartMinutes = defaults.integer(forKey: Key.customStart)
        self.customEndMinutes = defaults.integer(forKey: Key.customEnd)
        self.showFloatingCard = defaults.bool(forKey: Key.showFloatingCard)
        self.cardSize = CardSize(rawValue: defaults.string(forKey: Key.cardSize) ?? "") ?? .large
        self.cardStyle = CardStyle(rawValue: defaults.string(forKey: Key.cardStyle) ?? "") ?? .dark
        self.language = Language(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .chinese
        self.progressMode = ProgressMode(rawValue: defaults.string(forKey: Key.progressMode) ?? "") ?? .elapsed
        self.percentPrecision = PercentPrecision(rawValue: defaults.string(forKey: Key.percentPrecision) ?? "") ?? .decimal
        self.timeZoneID = defaults.string(forKey: Key.timeZoneID) ?? TimeZoneOption.systemID

        if startsTimer {
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - 语言

    func t(_ chinese: String, _ english: String) -> String {
        language == .chinese ? chinese : english
    }

    // MARK: - 时区

    var activeTimeZone: TimeZone {
        if timeZoneID == TimeZoneOption.systemID { return .current }
        return TimeZone(identifier: timeZoneID) ?? .current
    }

    var zoneOffsetText: String {
        Self.offsetText(for: activeTimeZone, at: now)
    }

    /// 右上角小徽标：跟随系统时只显示偏移，选了具体时区时带上地名。
    var zoneBadgeText: String {
        if timeZoneID == TimeZoneOption.systemID {
            return zoneOffsetText
        }
        let option = TimeZoneOption.all.first { $0.id == timeZoneID }
        let name = option?.name(language) ?? activeTimeZone.identifier
        return "\(name) \(zoneOffsetText)"
    }

    func zoneLabel(for option: TimeZoneOption) -> String {
        let zone: TimeZone
        if option.id == TimeZoneOption.systemID {
            zone = .current
        } else {
            zone = TimeZone(identifier: option.id) ?? .current
        }
        return "\(option.name(language)) · \(Self.offsetText(for: zone, at: now))"
    }

    static func offsetText(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60
        if minutes == 0 { return "UTC\(sign)\(hours)" }
        return "UTC\(sign)\(hours):" + String(format: "%02d", minutes)
    }

    private var calendar: Calendar {
        var result = Calendar.current
        result.timeZone = activeTimeZone
        return result
    }

    // MARK: - 时间窗口

    var window: DayWindow { window(at: now) }

    func window(at date: Date) -> DayWindow {
        let calendar = self.calendar
        let startOfDay = calendar.startOfDay(for: date)

        switch mode {
        case .natural:
            let end = calendar.date(byAdding: .day, value: 1, to: startOfDay)
                ?? startOfDay.addingTimeInterval(86_400)
            return DayWindow(start: startOfDay, end: end)

        case .custom:
            let start = time(on: startOfDay, minutes: customStartMinutes, calendar: calendar)
            let end = time(on: startOfDay, minutes: customEndMinutes, calendar: calendar)

            if customEndMinutes > customStartMinutes {
                return DayWindow(start: start, end: end)
            }
            if customEndMinutes == customStartMinutes {
                // 起止相同视为一整天。
                let next = calendar.date(byAdding: .day, value: 1, to: start)
                    ?? start.addingTimeInterval(86_400)
                return DayWindow(start: start, end: next)
            }

            // 跨夜窗口：选出当前所在的那一段。
            let minutesNow = minutesSinceMidnight(date, calendar: calendar)
            if minutesNow < customEndMinutes {
                let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay)
                    ?? startOfDay.addingTimeInterval(-86_400)
                let previousStart = time(on: previousDay, minutes: customStartMinutes, calendar: calendar)
                return DayWindow(start: previousStart, end: end)
            }
            let next = calendar.date(byAdding: .day, value: 1, to: end)
                ?? end.addingTimeInterval(86_400)
            return DayWindow(start: start, end: next)
        }
    }

    // MARK: - 进度

    /// 已经过去的时间比例（0...1），进度环始终按它画。
    var progress: Double {
        let window = window
        let elapsed = now.timeIntervalSince(window.start)
        return min(max(elapsed / window.duration, 0), 1)
    }

    /// 进入“已过 / 剩余”模式后的显示值。
    var displayedProgress: Double {
        switch progressMode {
        case .elapsed: return progress
        case .remaining: return 1 - progress
        }
    }

    var percentText: String {
        percentPrecision.format(displayedProgress)
    }

    var displayCaption: String {
        switch progressMode {
        case .elapsed: return t("今天已过", "Today elapsed")
        case .remaining: return t("今天还剩", "Today left")
        }
    }

    var remaining: TimeInterval { max(0, window.end.timeIntervalSince(now)) }
    var elapsed: TimeInterval { min(max(0, now.timeIntervalSince(window.start)), window.duration) }

    var remainingText: String { durationText(remaining) }
    var elapsedText: String { durationText(elapsed) }

    var remainingLine: String {
        t("还剩 \(durationText(remaining))", "\(durationText(remaining)) left")
    }

    var elapsedLine: String {
        t("已过 \(durationText(elapsed))", "\(durationText(elapsed)) elapsed")
    }

    /// 浮窗上的第二行：已过模式显示剩余，剩余模式显示已过。
    var cardSecondaryText: String {
        switch progressMode {
        case .elapsed: return remainingLine
        case .remaining: return elapsedLine
        }
    }

    // MARK: - 文案

    var todayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = activeTimeZone
        formatter.dateFormat = language == .chinese ? "M月d日 · EEEE" : "MMM d · EEEE"
        return formatter.string(from: now)
    }

    var windowTitle: String {
        let window = window
        let crossesDay = !calendar.isDate(window.start, inSameDayAs: window.end)
        let hours = window.duration / 3600
        let hoursText = hours == hours.rounded() ? String(Int(hours)) : String(format: "%.1f", hours)

        switch mode {
        case .natural:
            return t("自然日 · 00:00 – 24:00 · 共 24 小时",
                     "Natural day · 00:00 – 24:00 · 24h")
        case .custom:
            let start = clockText(window.start)
            let end = clockText(window.end)
            if language == .chinese {
                return "自定义 · \(start) – \(crossesDay ? "次日 " : "")\(end) · 共 \(hoursText) 小时"
            }
            return "Custom · \(start) – \(crossesDay ? "next day " : "")\(end) · \(hoursText)h"
        }
    }

    var moodText: String {
        switch progress {
        case ..<0.10: return t("新的一天，慢慢来", "A fresh day — take it slow")
        case ..<0.30: return t("上午好，先做最重要的一件事", "Good morning — start with the most important thing")
        case ..<0.50: return t("时间过半之前，把要紧的事推进", "Push the important work before the day is half gone")
        case ..<0.75: return t("今天已过去大半，专注收尾", "Most of the day is gone — stay focused and wrap up")
        case ..<0.90: return t("剩下的时间不多了，别分心", "Not much time left today — don't get distracted")
        default: return t("今天快要结束了，明天见", "The day is almost over — see you tomorrow")
        }
    }

    var milestoneText: String {
        let window = window
        let milestones: [(threshold: Double, zh: String, en: String)] = [
            (0.25, "四分之一", "a quarter"),
            (0.5, "一半", "half"),
            (0.75, "四分之三", "three quarters"),
        ]
        for milestone in milestones where progress < milestone.threshold {
            let remaining = (milestone.threshold - progress) * window.duration
            if language == .chinese {
                return "再过 \(durationText(remaining))，今天就走完\(milestone.zh)了"
            }
            return "In \(durationText(remaining)), \(milestone.en) of today will be gone"
        }
        return t("今天已经走完四分之三，把最重要的事收个尾",
                 "Three quarters of today is gone — wrap up what matters")
    }

    // MARK: - 时间文案

    func durationText(_ time: TimeInterval) -> String {
        let total = Int(time.rounded())
        if language == .chinese {
            if total < 60 { return "不到 1 分钟" }
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            if hours == 0 { return "\(minutes) 分钟" }
            if minutes == 0 { return "\(hours) 小时" }
            return "\(hours) 小时 \(minutes) 分"
        } else {
            if total < 60 { return "<1m" }
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            if hours == 0 { return "\(minutes)m" }
            if minutes == 0 { return "\(hours)h" }
            return "\(hours)h \(minutes)m"
        }
    }

    // MARK: - 私有

    private func clockText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = activeTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func time(on day: Date, minutes: Int, calendar: Calendar) -> Date {
        let clamped = min(max(minutes, 0), 24 * 60)
        let hour = clamped / 60
        let minute = clamped % 60
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private func minutesSinceMidnight(_ date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.now = self.dateProvider()
            }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
