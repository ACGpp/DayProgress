## 安装：优先下载 DMG

1. 下载 **DayProgress-1.2.2.dmg** 并双击打开。
2. 先退出旧版，将 **DayProgress.app** 拖到 **Applications**；更新时替换即可，设置保留。
3. 从「应用程序」打开一次。如果被 macOS 拦截：**系统设置 → 隐私与安全性 → 仍要打开**。
4. 启动后看屏幕右上角的沙漏；没有 Dock 图标。完成后可推出磁盘映像。

DMG 和 ZIP 均附 **「先看这里-安装指南.html」** 双语指南。macOS 13+，Apple Silicon / Intel 通用。没有 Apple Developer ID 签名和公证，DMG 不会绕过系统安全检查；无需关闭全局安全功能。

## 更新内容

- 修复设置页每次时钟刷新时积累 Observation 跟踪对象的问题。
- 菜单栏仅在显示内容变化时更新；隐藏浮窗释放视图，按需创建毛玻璃。
- 支持「仅菜单栏」显示方式。
- 复用日期格式器，唤醒或系统时间变化后立即刷新。
- 新增带安装指南的 DMG / ZIP，以及 SHA-256 校验和。

回归测试及 100 次浮窗生命周期测试通过。1,200 次加速刷新探针中，内存从 57.3 MB 降至 43.2 MB，相关 Observation 字典由 15,001 份降至 21 份。这是独立探针对比，不代表完整应用的长期内存保证；24 小时验证尚未完成。

## English

Download the DMG, quit the old version, and drag the app into Applications. Open it there once; if blocked, use **System Settings → Privacy & Security → Open Anyway**. The app is not Developer ID signed or notarized. Both DMG and ZIP include a bilingual installation guide.

This release reduces retained settings observations, updates menu text only when needed, releases hidden floating views, and adds menu-bar-only mode. macOS 13+, universal Apple Silicon / Intel binary. Existing preferences are preserved.
