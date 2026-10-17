import Foundation
import ServiceManagement

/// 登录时自动启动（SMAppService）。未放入「应用程序」时可能注册失败，界面会给出提示。
@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 已注册但用户还没在系统设置里批准。
    static var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
