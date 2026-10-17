import Foundation
import ServiceManagement

/// 登录时自动启动（SMAppService）。未放入「应用程序」时可能注册失败，界面会给出提示。
@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
