import SwiftUI

/// 一天的配色：清晨薄荷 → 正午蓝 → 下午蓝紫 → 傍晚粉 → 日落橙 → 入夜琥珀。
enum DayTheme {
    private struct Stop {
        let position: Double
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    private static let stops: [Stop] = [
        Stop(position: 0.00, red: 0.18, green: 0.83, blue: 0.68),
        Stop(position: 0.25, red: 0.30, green: 0.72, blue: 1.00),
        Stop(position: 0.42, red: 0.48, green: 0.58, blue: 1.00),
        Stop(position: 0.55, red: 0.72, green: 0.47, blue: 0.98),
        Stop(position: 0.65, red: 1.00, green: 0.52, blue: 0.74),
        Stop(position: 0.78, red: 1.00, green: 0.62, blue: 0.27),
        Stop(position: 1.00, red: 1.00, green: 0.75, blue: 0.32),
    ]

    static func color(at fraction: Double) -> Color {
        let t = min(max(fraction, 0), 1)
        guard let first = stops.first else { return .white }
        if t <= first.position { return color(first) }

        for index in 0..<(stops.count - 1) {
            let start = stops[index]
            let end = stops[index + 1]
            if t <= end.position {
                let span = max(end.position - start.position, 0.0001)
                let local = CGFloat((t - start.position) / span)
                return color(
                    red: start.red + (end.red - start.red) * local,
                    green: start.green + (end.green - start.green) * local,
                    blue: start.blue + (end.blue - start.blue) * local
                )
            }
        }
        return color(stops[stops.count - 1])
    }

    private static func color(_ stop: Stop) -> Color {
        color(red: stop.red, green: stop.green, blue: stop.blue)
    }

    private static func color(red: CGFloat, green: CGFloat, blue: CGFloat) -> Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue))
    }

    /// 只为实际画出来的那一段弧生成渐变，这样末端不会有颜色接缝。
    static func angularGradient(from start: Double, to end: Double) -> AngularGradient {
        let sampleCount = 24
        let span = max(end - start, 0.0001)
        let stops = (0...sampleCount).map { index in
            let fraction = start + span * Double(index) / Double(sampleCount)
            return Gradient.Stop(
                color: color(at: fraction),
                location: Double(index) / Double(sampleCount)
            )
        }
        return AngularGradient(
            gradient: Gradient(stops: stops),
            center: .center,
            startAngle: .degrees(start * 360),
            endAngle: .degrees(end * 360)
        )
    }
}

/// 桌面浮窗用的平滑进度环。默认按“已过”方向填充，剩余模式从终点往回收。
struct DayRing: View {
    var progress: Double
    var lineWidth: CGFloat = 7
    var mode: ProgressMode = .elapsed

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let ringSize = max(1, side - lineWidth)
            let radius = ringSize / 2
            let clamped = min(max(progress, 0), 1)
            let shown = mode == .elapsed ? clamped : 1 - clamped
            let startFraction = mode == .elapsed ? 0 : 1 - shown
            let endFraction = mode == .elapsed ? shown : 1
            let knobFraction = mode == .elapsed ? shown : startFraction
            let angle = Angle.degrees(knobFraction * 360 - 90)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: lineWidth)

                if shown > 0.002 {
                    Circle()
                        .trim(from: startFraction, to: max(endFraction, startFraction + 0.0001))
                        .stroke(
                            DayTheme.angularGradient(
                                from: startFraction,
                                to: max(endFraction, startFraction + 0.0001)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                if shown > 0.01 && shown < 0.995 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: max(3, lineWidth * 0.5), height: max(3, lineWidth * 0.5))
                        .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                        .shadow(color: .black.opacity(0.4), radius: 1.5, y: 0.5)
                }
            }
            .frame(width: ringSize, height: ringSize)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

/// 菜单栏弹窗用的 24 格“一天刻度环”。剩余模式下点亮的是“今天剩下的那一段”。
struct SegmentedDayRing: View {
    var progress: Double
    var lineWidth: CGFloat = 15
    var slots: Int = 24
    var mode: ProgressMode = .elapsed

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let radius = max(1, side / 2 - lineWidth / 2)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let slotAngle = 360.0 / Double(slots)
            let gap = 2.2
            let elapsedSlots = min(max(progress, 0), 1) * Double(slots)
            let remainingSlots = Double(slots) - elapsedSlots
            let track = GraphicsContext.Shading.color(Color.primary.opacity(0.08))

            for index in 0..<slots {
                let start = -90.0 + Double(index) * slotAngle + gap / 2
                let end = -90.0 + Double(index + 1) * slotAngle - gap / 2

                var trackPath = Path()
                trackPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(start),
                    endAngle: .degrees(end),
                    clockwise: false
                )
                context.stroke(
                    trackPath,
                    with: track,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                let fill: Double
                switch mode {
                case .elapsed:
                    fill = min(max(elapsedSlots - Double(index), 0), 1)
                case .remaining:
                    fill = min(max(remainingSlots - Double(slots - 1 - index), 0), 1)
                }

                if fill > 0.015 {
                    let span = end - start
                    var fillPath = Path()
                    if mode == .elapsed {
                        fillPath.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(start),
                            endAngle: .degrees(start + span * fill),
                            clockwise: false
                        )
                    } else {
                        fillPath.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(end - span * fill),
                            endAngle: .degrees(end),
                            clockwise: false
                        )
                    }
                    let shade = GraphicsContext.Shading.color(
                        DayTheme.color(at: (Double(index) + 0.5) / Double(slots))
                    )
                    context.stroke(
                        fillPath,
                        with: shade,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                }
            }
        }
    }
}
