import Foundation

/// 界面语言。
enum Language: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var title: String {
        self == .chinese ? "中文" : "English"
    }

    var locale: Locale {
        Locale(identifier: self == .chinese ? "zh_CN" : "en_US")
    }

    /// 新用户默认跟随系统语言。
    static var systemDefault: Language {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .chinese : .english
    }
}

/// 百分比显示方式：已过 / 剩余。
enum ProgressMode: String, CaseIterable, Identifiable {
    case elapsed
    case remaining

    var id: String { rawValue }

    func title(_ language: Language) -> String {
        switch (self, language) {
        case (.elapsed, .chinese): return "已过"
        case (.remaining, .chinese): return "剩余"
        case (.elapsed, .english): return "Elapsed"
        case (.remaining, .english): return "Left"
        }
    }
}

/// 百分比精度。
enum PercentPrecision: String, CaseIterable, Identifiable {
    case integer
    case decimal

    var id: String { rawValue }

    func title(_ language: Language) -> String {
        switch (self, language) {
        case (.integer, .chinese): return "整数"
        case (.decimal, .chinese): return "一位小数"
        case (.integer, .english): return "Whole"
        case (.decimal, .english): return "Decimal"
        }
    }

    func format(_ fraction: Double) -> String {
        let clamped = min(max(fraction, 0), 1)
        let digits = self == .integer ? 0 : 1
        let factor = pow(10.0, Double(digits))
        // 向下取整到显示精度，避免 99.96% 提前显示成 100%。
        let percent = floor(clamped * 100 * factor + 1e-9) / factor
        return String(format: "%.\(digits)f%%", percent)
    }
}

/// 可选时区。id 为 "system" 时跟随系统。
struct TimeZoneOption: Identifiable, Hashable {
    let id: String
    let zh: String
    let en: String

    static let systemID = "system"

    static let all: [TimeZoneOption] = [
        TimeZoneOption(id: systemID, zh: "跟随系统", en: "System"),
        TimeZoneOption(id: "UTC", zh: "UTC", en: "UTC"),
        TimeZoneOption(id: "Asia/Shanghai", zh: "上海", en: "Shanghai"),
        TimeZoneOption(id: "Asia/Tokyo", zh: "东京", en: "Tokyo"),
        TimeZoneOption(id: "Asia/Seoul", zh: "首尔", en: "Seoul"),
        TimeZoneOption(id: "Asia/Singapore", zh: "新加坡", en: "Singapore"),
        TimeZoneOption(id: "Asia/Bangkok", zh: "曼谷", en: "Bangkok"),
        TimeZoneOption(id: "Asia/Kolkata", zh: "印度", en: "India"),
        TimeZoneOption(id: "Asia/Dubai", zh: "迪拜", en: "Dubai"),
        TimeZoneOption(id: "Europe/London", zh: "伦敦", en: "London"),
        TimeZoneOption(id: "Europe/Paris", zh: "巴黎", en: "Paris"),
        TimeZoneOption(id: "Europe/Berlin", zh: "柏林", en: "Berlin"),
        TimeZoneOption(id: "Europe/Moscow", zh: "莫斯科", en: "Moscow"),
        TimeZoneOption(id: "America/New_York", zh: "纽约", en: "New York"),
        TimeZoneOption(id: "America/Chicago", zh: "芝加哥", en: "Chicago"),
        TimeZoneOption(id: "America/Denver", zh: "丹佛", en: "Denver"),
        TimeZoneOption(id: "America/Los_Angeles", zh: "洛杉矶", en: "Los Angeles"),
        TimeZoneOption(id: "America/Sao_Paulo", zh: "圣保罗", en: "São Paulo"),
        TimeZoneOption(id: "Australia/Sydney", zh: "悉尼", en: "Sydney"),
        TimeZoneOption(id: "Pacific/Auckland", zh: "奥克兰", en: "Auckland"),
    ]

    func name(_ language: Language) -> String {
        language == .chinese ? zh : en
    }
}
