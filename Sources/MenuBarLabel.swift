import Combine
import SwiftUI

struct MenuBarDisplay: Equatable {
    let percent: String
    let caption: String

    @MainActor
    init(clock: DayClock) {
        percent = clock.percentText
        caption = clock.displayCaption
    }
}

/// Keep clock ticks out of the App/Scene graph and publish only visible changes.
@MainActor
final class MenuBarDisplayModel: ObservableObject {
    @Published private(set) var display: MenuBarDisplay
    private var subscription: AnyCancellable?

    init(clock: DayClock) {
        display = MenuBarDisplay(clock: clock)
        subscription = clock.objectWillChange
            // @Published sends before the value changes. Read on the next run-loop turn.
            .receive(on: RunLoop.main)
            .sink { [weak self, weak clock] in
                guard let self, let clock else { return }
                let next = MenuBarDisplay(clock: clock)
                if next != self.display { self.display = next }
            }
    }
}

struct MenuBarLabel: View {
    @StateObject private var model: MenuBarDisplayModel

    init(clock: DayClock) {
        _model = StateObject(wrappedValue: MenuBarDisplayModel(clock: clock))
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hourglass")
                .font(.system(size: 11, weight: .medium))
            Text(model.display.percent)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
        }
        .accessibilityLabel("\(model.display.caption) \(model.display.percent)")
    }
}
