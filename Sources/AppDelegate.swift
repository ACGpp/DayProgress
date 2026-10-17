import AppKit
import Combine
import SwiftUI

/// 无边框、不抢焦点的桌面浮窗。
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var effectView: NSVisualEffectView?
    private var hostingView: NSHostingView<FloatingCardView>?
    private var cancellables: Set<AnyCancellable> = []
    private var welcomeWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let clock = DayClock.shared
        createPanel(clock: clock)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        clock.$showFloatingCard
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                self?.setPanelVisible(visible)
            }
            .store(in: &cancellables)

        clock.$cardSize
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] size in
                self?.apply(cardSize: size)
            }
            .store(in: &cancellables)

        clock.$cardStyle
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] style in
                self?.apply(cardStyle: style)
            }
            .store(in: &cancellables)

        // 开发调试：DAYPROGRESS_DEBUG_POPOVER=1 / settings 时额外打开一个无边框窗口展示面板，方便截图。
        if let debug = ProcessInfo.processInfo.environment["DAYPROGRESS_DEBUG_POPOVER"] {
            let hosting = NSHostingView(rootView: PopoverView(clock: clock, startsOnSettings: debug == "settings"))
            let fitting = hosting.fittingSize
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: fitting),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.title = "DayProgress · Panel"
            window.contentView = hosting
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
            window.setFrameOrigin(NSPoint(x: 150, y: 120))
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }

        presentWelcomeIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - 首次启动引导

    /// 第一次打开时用一个轻量窗口介绍菜单栏、浮窗和退出入口，只出现一次。
    private func presentWelcomeIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: DayClock.Key.hasSeenWelcome) else { return }
        defaults.set(true, forKey: DayClock.Key.hasSeenWelcome)

        let language = DayClock.shared.language
        let hosting = NSHostingView(
            rootView: WelcomeView(language: language) { [weak self] in
                self?.welcomeWindow?.close()
            }
        )
        let size = hosting.fittingSize

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = language == .chinese ? "欢迎使用 DayProgress" : "Welcome to DayProgress"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.contentView = hosting
        window.center()
        window.delegate = self
        welcomeWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - 浮窗

    private func createPanel(clock: DayClock) {
        let card = clock.cardSize
        let contentSize = card.size
        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = clock.cardStyle != .plain
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.acceptsMouseMovedEvents = false

        let container = NSView(frame: NSRect(origin: .zero, size: contentSize))
        container.autoresizingMask = [.width, .height]

        let effect = NSVisualEffectView(frame: container.bounds)
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = card.cornerRadius
        effect.layer?.cornerCurve = .continuous
        effect.layer?.masksToBounds = true
        effect.isHidden = clock.cardStyle != .glass
        container.addSubview(effect)

        let hosting = NSHostingView(rootView: FloatingCardView(clock: clock))
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        container.addSubview(hosting)

        panel.contentView = container
        self.panel = panel
        self.effectView = effect
        self.hostingView = hosting

        restorePositionIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: panel
        )
    }

    private func apply(cardSize: CardSize) {
        guard let panel, let container = panel.contentView else { return }
        let newSize = cardSize.size
        var frame = panel.frame
        let topRight = NSPoint(x: frame.maxX, y: frame.maxY)
        frame.size = newSize
        frame.origin = clampOrigin(
            NSPoint(x: topRight.x - newSize.width, y: topRight.y - newSize.height),
            size: newSize
        )
        panel.setFrame(frame, display: true)
        container.frame = NSRect(origin: .zero, size: newSize)
        effectView?.frame = container.bounds
        hostingView?.frame = container.bounds
        effectView?.layer?.cornerRadius = cardSize.cornerRadius
        persistPosition()
        panel.invalidateShadow()
    }

    private func apply(cardStyle: CardStyle) {
        effectView?.isHidden = cardStyle != .glass
        panel?.hasShadow = cardStyle != .plain
        panel?.invalidateShadow()
    }

    private func setPanelVisible(_ visible: Bool) {
        guard let panel else { return }
        if visible {
            clampPanelIntoView()
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    /// 屏幕变化 / 重新显示时把浮窗拉回可见区域，避免拖到屏幕外后找不回来。
    private func clampPanelIntoView() {
        guard let panel else { return }
        let origin = clampOrigin(panel.frame.origin, size: panel.frame.size)
        if origin != panel.frame.origin {
            panel.setFrameOrigin(origin)
        }
    }

    @objc private func screenParametersChanged() {
        clampPanelIntoView()
    }

    // MARK: - 位置

    private func restorePositionIfNeeded() {
        guard let panel else { return }
        let defaults = UserDefaults.standard
        let size = panel.frame.size

        let hasTopRight = defaults.object(forKey: DayClock.Key.floatingTopRightX) != nil
            && defaults.object(forKey: DayClock.Key.floatingTopRightY) != nil
        let hasOrigin = defaults.object(forKey: DayClock.Key.floatingX) != nil
            && defaults.object(forKey: DayClock.Key.floatingY) != nil

        if hasTopRight {
            let topRight = NSPoint(
                x: defaults.double(forKey: DayClock.Key.floatingTopRightX),
                y: defaults.double(forKey: DayClock.Key.floatingTopRightY)
            )
            let origin = NSPoint(x: topRight.x - size.width, y: topRight.y - size.height)
            panel.setFrameOrigin(clampOrigin(origin, size: size))
        } else if hasOrigin {
            // 兼容旧版本保存的左下角坐标。
            let stored = NSPoint(
                x: defaults.double(forKey: DayClock.Key.floatingX),
                y: defaults.double(forKey: DayClock.Key.floatingY)
            )
            panel.setFrameOrigin(clampOrigin(stored, size: size))
        } else if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - size.width - 8,
                y: visible.maxY - size.height - 8
            )
            panel.setFrameOrigin(origin)
        }

        persistPosition()
    }

    private func clampOrigin(_ origin: NSPoint, size: NSSize) -> NSPoint {
        let frame = NSRect(origin: origin, size: size)
        let screen = NSScreen.screens.first { $0.frame.intersects(frame) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return origin }
        let margin: CGFloat = 8
        var point = origin
        let minX = visible.minX + margin
        let maxX = max(minX, visible.maxX - size.width - margin)
        let minY = visible.minY + margin
        let maxY = max(minY, visible.maxY - size.height - margin)
        point.x = min(max(point.x, minX), maxX)
        point.y = min(max(point.y, minY), maxY)
        return point
    }

    private func persistPosition() {
        guard let panel else { return }
        let frame = panel.frame
        let defaults = UserDefaults.standard
        defaults.set(frame.origin.x, forKey: DayClock.Key.floatingX)
        defaults.set(frame.origin.y, forKey: DayClock.Key.floatingY)
        defaults.set(frame.maxX, forKey: DayClock.Key.floatingTopRightX)
        defaults.set(frame.maxY, forKey: DayClock.Key.floatingTopRightY)
    }

    @objc private func panelDidMove(_ notification: Notification) {
        persistPosition()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closed = notification.object as? NSWindow, closed === welcomeWindow else { return }
        welcomeWindow = nil
    }
}
