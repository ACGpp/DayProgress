import SwiftUI

@main
struct DayProgressApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let clock = DayClock.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverView(clock: clock)
        } label: {
            MenuBarLabel(clock: clock)
        }
        .menuBarExtraStyle(.window)
    }
}
