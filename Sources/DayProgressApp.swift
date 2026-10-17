import SwiftUI

@main
struct DayProgressApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var clock = DayClock.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverView(clock: clock)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .medium))
                Text(clock.percentText)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
            .accessibilityLabel("\(clock.displayCaption) \(clock.percentText)")
        }
        .menuBarExtraStyle(.window)
    }
}
