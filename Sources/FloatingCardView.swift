import AppKit
import SwiftUI

/// 桌面浮窗：始终置顶、可拖动，支持三档尺寸和深色 / 毛玻璃 / 透明外观。
struct FloatingCardView: View {
    @ObservedObject var clock: DayClock

    private var cardSize: CardSize { clock.cardSize }

    private var contentShadowOpacity: Double {
        clock.cardStyle == .plain ? 0.55 : 0
    }

    var body: some View {
        content
            .frame(width: cardSize.size.width, height: cardSize.size.height)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: cardSize.cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(contentShadowOpacity),
                radius: contentShadowOpacity > 0 ? 2.5 : 0
            )
            .transaction { transaction in transaction.animation = nil }
            .contextMenu {
                Button(clock.t("隐藏浮窗", "Hide card")) { clock.showFloatingCard = false }
                Button(clock.t("退出 DayProgress", "Quit DayProgress")) { NSApp.terminate(nil) }
            }
    }

    // MARK: - 布局

    @ViewBuilder
    private var content: some View {
        switch cardSize {
        case .large:
            largeContent
        case .medium:
            mediumContent
        case .mini:
            miniContent
        }
    }

    private var largeContent: some View {
        HStack(spacing: 16) {
            DayRing(progress: clock.progress, lineWidth: 7, mode: clock.progressMode)
                .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 2) {
                Text(clock.displayCaption)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.52))
                    .lineLimit(1)
                Text(clock.percentText)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                Text(clock.cardSecondaryText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var mediumContent: some View {
        HStack(spacing: 12) {
            DayRing(progress: clock.progress, lineWidth: 6, mode: clock.progressMode)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(clock.percentText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                Text(clock.cardSecondaryText)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var miniContent: some View {
        ZStack {
            DayRing(progress: clock.progress, lineWidth: 9, mode: clock.progressMode)
                .frame(width: 74, height: 74)
            Text(clock.percentText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 外观

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: cardSize.cornerRadius, style: .continuous)
        switch clock.cardStyle {
        case .dark:
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.15, blue: 0.20),
                            Color(red: 0.07, green: 0.08, blue: 0.11),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    shape.fill(
                        RadialGradient(
                            colors: [DayTheme.color(at: clock.progress).opacity(0.20), .clear],
                            center: .topTrailing,
                            startRadius: 8,
                            endRadius: 190
                        )
                    )
                )
        case .glass:
            // 毛玻璃由窗口里的 NSVisualEffectView 提供，这里只叠一层薄薄的暗色保证可读。
            shape.fill(Color.black.opacity(0.16))
        case .plain:
            Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        if clock.cardStyle == .plain {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: cardSize.cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}
