import SwiftUI

/// 首次启动引导：告诉用户菜单栏、浮窗和退出分别在哪里。
struct WelcomeView: View {
    let language: Language
    var onContinue: () -> Void

    private func t(_ zh: String, _ en: String) -> String {
        language == .chinese ? zh : en
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 13) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(t("欢迎使用 DayProgress", "Welcome to DayProgress"))
                        .font(.system(size: 20, weight: .bold))
                    Text(t("把今天放在抬头能看到的地方。", "Keep today's progress in sight."))
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 18) {
                row(icon: "menubar.rectangle",
                    title: t("点菜单栏图标", "Click the menu bar icon"),
                    detail: t("打开面板，看今天、换设置、退出 App。", "Open the panel for progress, settings and quit."))
                row(icon: "hand.draw",
                    title: t("拖动浮窗", "Drag the floating card"),
                    detail: t("摆到喜欢的位置，右键可以随时隐藏。", "Place it anywhere; right-click to hide it."))
                row(icon: "gearshape",
                    title: t("按需定制", "Make it yours"),
                    detail: t("尺寸、外观、语言、时区、自定义时段都在设置里。", "Size, style, language, time zone and custom hours live in Settings."))
            }

            Spacer(minLength: 20)

            HStack {
                Text(t("祝你天天开心。", "Have a good day."))
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onContinue) {
                    Text(t("开始使用", "Get started"))
                        .frame(minWidth: 76)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 440)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func row(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.68, blue: 0.60),
                                    Color(red: 0.24, green: 0.56, blue: 1.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
