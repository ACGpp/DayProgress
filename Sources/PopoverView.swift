import AppKit
import Combine
import SwiftUI

/// Settings do not depend on every clock tick. Keep their controls out of the refresh path.
@MainActor
final class PopoverClockModel: ObservableObject {
    let clock: DayClock
    var showingSettings: Bool
    private var settingsSignature: [String]
    private var subscription: AnyCancellable?

    init(clock: DayClock, showingSettings: Bool) {
        self.clock = clock
        self.showingSettings = showingSettings
        settingsSignature = Self.signature(clock)
        subscription = clock.objectWillChange.receive(on: RunLoop.main).sink { [weak self] in
            guard let self else { return }
            let next = Self.signature(self.clock)
            if !self.showingSettings || next != self.settingsSignature {
                self.objectWillChange.send()
            }
            self.settingsSignature = next
        }
    }

    private static func signature(_ clock: DayClock) -> [String] {
        [clock.mode.rawValue, String(clock.customStartMinutes), String(clock.customEndMinutes),
         String(clock.showFloatingCard), clock.cardSize.rawValue, clock.cardStyle.rawValue,
         clock.language.rawValue, clock.progressMode.rawValue, clock.percentPrecision.rawValue,
         clock.timeZoneID] + TimeZoneOption.all.map { clock.zoneLabel(for: $0) }
    }
}

/// 菜单栏下拉面板：主页显示一天进度，齿轮进入设置页。
struct PopoverView: View {
    @StateObject private var model: PopoverClockModel
    private var clock: DayClock { model.clock }

    @State private var page: Page
    @State private var loginItemOn = false
    @State private var loginItemNeedsApproval = false
    @State private var loginItemError: String?

    enum Page {
        case main
        case settings
    }

    init(clock: DayClock, startsOnSettings: Bool = false) {
        _model = StateObject(wrappedValue: PopoverClockModel(clock: clock, showingSettings: startsOnSettings))
        _page = State(initialValue: startsOnSettings ? .settings : .main)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if page == .main {
                mainContent
            } else {
                settingsContent
            }
        }
        .padding(18)
        .frame(width: 336)
        .onChange(of: page) { model.showingSettings = $0 == .settings }
        .onAppear {
            loginItemOn = LoginItem.isEnabled
            loginItemNeedsApproval = LoginItem.requiresApproval
        }
    }

    // MARK: - 顶栏

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            if page == .settings {
                Button {
                    page = .main
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(clock.t("返回", "Back"))

                Text(clock.t("设置", "Settings"))
                    .font(.system(size: 13, weight: .semibold))

                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(clock.todayTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(clock.zoneBadgeText)
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(clock.windowTitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Button {
                    page = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(clock.t("设置", "Settings"))
            }
        }
    }

    // MARK: - 主页

    private var mainContent: some View {
        VStack(spacing: 0) {
            ringBlock
                .padding(.top, 14)

            statsRow
                .padding(.top, 14)

            Text(clock.moodText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            mainSeparator

            footer
        }
    }

    private var ringBlock: some View {
        ZStack {
            SegmentedDayRing(progress: clock.progress, lineWidth: 15, slots: 24, mode: clock.progressMode)
                .frame(width: 188, height: 188)

            VStack(spacing: 2) {
                Text(clock.percentText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(clock.displayCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat(title: clock.t("已过", "Elapsed"), value: clock.elapsedText)
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 26)
            stat(title: clock.t("剩余", "Left"), value: clock.remainingText)
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(clock.milestoneText)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(clock.t("退出", "Quit")) { NSApp.terminate(nil) }
                .buttonStyle(.link)
                .font(.system(size: 11))
        }
    }

    // MARK: - 设置页

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingRow(clock.t("计日方式", "Day range")) {
                Picker("", selection: binding(\.mode)) {
                    ForEach(DayMode.allCases) { mode in
                        Text(mode.title(clock.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 168)
            }

            if clock.mode == .custom {
                settingRow(clock.t("开始", "Start")) {
                    timePicker(binding(\.customStartMinutes))
                }
                settingRow(clock.t("结束", "End")) {
                    timePicker(binding(\.customEndMinutes))
                }
            }

            settingRow(clock.t("进度模式", "Progress")) {
                Picker("", selection: binding(\.progressMode)) {
                    ForEach(ProgressMode.allCases) { mode in
                        Text(mode.title(clock.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 168)
            }

            settingRow(clock.t("百分比", "Percent")) {
                Picker("", selection: binding(\.percentPrecision)) {
                    Text("77%").tag(PercentPrecision.integer)
                    Text("77.8%").tag(PercentPrecision.decimal)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 168)
            }

            thinSeparator

            settingRow(clock.t("显示方式", "Display")) {
                Picker("", selection: binding(\.showFloatingCard)) {
                    Text(clock.t("菜单栏 + 浮窗", "Menu bar + card")).tag(true)
                    Text(clock.t("仅菜单栏", "Menu bar only")).tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }

            if !clock.showFloatingCard {
                Text(clock.t("桌面浮窗已隐藏，只保留菜单栏百分比；随时可以切回来。",
                             "Floating card hidden — only the menu bar percentage stays. Switch back anytime."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if clock.showFloatingCard {
                settingRow(clock.t("浮窗尺寸", "Card size")) {
                    Picker("", selection: binding(\.cardSize)) {
                        ForEach(CardSize.allCases) { size in
                            Text(size.title(clock.language)).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 168)
                }

                settingRow(clock.t("浮窗样式", "Card style")) {
                    Picker("", selection: binding(\.cardStyle)) {
                        ForEach(CardStyle.allCases) { style in
                            Text(style.title(clock.language)).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 168)
                }
            }

            thinSeparator

            settingRow(clock.t("语言", "Language")) {
                Picker("", selection: binding(\.language)) {
                    ForEach(Language.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 168)
            }

            settingRow(clock.t("时区", "Time zone")) {
                Picker("", selection: binding(\.timeZoneID)) {
                    ForEach(TimeZoneOption.all) { option in
                        Text(clock.zoneLabel(for: option)).tag(option.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 192)
            }

            HStack {
                Text(clock.t("登录时启动", "Launch at login"))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: loginBinding)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            if loginItemNeedsApproval {
                Text(clock.t("已注册，还需要在系统设置的「登录项」里允许。",
                             "Registered — approve it in System Settings → Login Items."))
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let loginItemError {
                Text(loginItemError)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button(clock.t("完成", "Done")) {
                    page = .main
                }
                .buttonStyle(.link)
                .font(.system(size: 11, weight: .semibold))
            }
            .padding(.top, 4)
        }
        .padding(.top, 14)
    }

    private func settingRow<Content: View>(_ title: String,
                                           @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
            Spacer(minLength: 12)
            content()
        }
    }

    private func timePicker(_ minutes: Binding<Int>) -> some View {
        HStack(spacing: 2) {
            Picker("", selection: hourBinding(minutes)) {
                ForEach(0..<24) { hour in
                    Text(String(format: "%02d", hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 56)

            Text(":")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Picker("", selection: minuteBinding(minutes)) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 56)
        }
    }

    private var mainSeparator: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 1)
            .padding(.vertical, 12)
    }

    private var thinSeparator: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 1)
            .padding(.vertical, 3)
    }

    // MARK: - Binding

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<DayClock, Value>) -> Binding<Value> {
        Binding(get: { clock[keyPath: keyPath] }, set: { clock[keyPath: keyPath] = $0 })
    }

    private func hourBinding(_ minutes: Binding<Int>) -> Binding<Int> {
        Binding(
            get: { minutes.wrappedValue / 60 },
            set: { hour in
                let minute = minutes.wrappedValue % 60
                minutes.wrappedValue = hour * 60 + minute
            }
        )
    }

    private func minuteBinding(_ minutes: Binding<Int>) -> Binding<Int> {
        Binding(
            get: { (minutes.wrappedValue % 60) / 5 * 5 },
            set: { minute in
                minutes.wrappedValue = (minutes.wrappedValue / 60) * 60 + minute
            }
        )
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { loginItemOn },
            set: { newValue in
                do {
                    try LoginItem.setEnabled(newValue)
                    loginItemError = nil
                } catch {
                    loginItemError = clock.t(
                        "没能设置登录启动：\(error.localizedDescription)。可以先把 App 放进「应用程序」文件夹再试。",
                        "Couldn't update login item: \(error.localizedDescription). Try moving the app into Applications first."
                    )
                }
                loginItemOn = LoginItem.isEnabled
            loginItemNeedsApproval = LoginItem.requiresApproval
            }
        )
    }
}
