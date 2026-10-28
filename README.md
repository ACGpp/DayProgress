<p align="center">
  <img src="docs/icon.png" width="112" alt="DayProgress icon">
</p>

<h1 align="center">DayProgress · 今日进度</h1>

<p align="center">
  <b>一个 macOS 菜单栏小工具：把“今天过去了多少”变成随时能看见的百分比。</b><br>
  🌐 <a href="https://ACGpp.github.io/DayProgress/">在线主页</a> · <a href="README.en.md">English</a> · 中文
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/SwiftUI-%F0%9F%A7%A9-orange" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT">
</p>

## 当前版本

最新发布版：[**v1.2.2**](https://github.com/ACGpp/DayProgress/releases/tag/v1.2.2)（2026-10-28）。`main` 是当前开发主线，包含本次内存优化、安装包改进和官网修复；要构建与已发布版本一致的源码，请切换到 `v1.2.2` 标签。

- **更少的内存积累**：设置页不再随每次时钟刷新重建，菜单栏仅在文字变化时更新；隐藏浮窗释放视图。
- **更直观的安装**：[下载 DMG](https://github.com/ACGpp/DayProgress/releases/download/v1.2.2/DayProgress-1.2.2.dmg)，内含 Applications 入口和双语指南；也可先看[在线安装指南](https://acgpp.github.io/DayProgress/install.html)。
- **仅菜单栏模式**：可在设置中隐藏浮窗，保留菜单栏百分比。

详见 [更新日志](CHANGELOG.md)。性能对比使用独立探针，完整应用的 24 小时稳定性尚未验证，测量口径见[性能记录](docs/memory-performance.md)。

## 安装

**要求**：macOS 13 或更高版本 · 通用二进制（Apple Silicon + Intel）· 免费开源（MIT）。

### 下载后就能看到安装引导

1. **下载 DMG**：打开 [最新 Release](https://github.com/ACGpp/DayProgress/releases/latest)，选择 `DayProgress-x.y.z.dmg`（Apple Silicon / Intel 通用）。
2. **双击打开磁盘映像**：里面有 `DayProgress.app`、`Applications` 入口，以及 **「先看这里-安装指南.html」**。先退出旧版，再把 App 拖进 Applications；更新时选择替换，设置会保留。
3. **从「应用程序」首次打开**：若被拦截，按下面的「仍要打开」步骤处理。安装完成后推出磁盘映像。

也提供 ZIP：解压后是带相同安装指南的文件夹，不再只有一个 App。发布页的 `SHA256SUMS.txt` 可用于核对下载完整性。

### 第一次打开：Gatekeeper 会拦一次

我们目前没有 Apple Developer ID 签名和公证。App 仅做 **ad-hoc 签名**，DMG 不会绕过安全检查，从网上下载后 macOS 会拦截首次启动。被拦时：

1. 打开 **「系统设置 → 隐私与安全性」**，向下找到 DayProgress 的拦截提示。
2. 点 **「仍要打开」**（英文界面为 **Open Anyway**），按系统提示确认（可能需要登录密码）。
3. 回到「应用程序」再次双击 DayProgress。

macOS 15 及以后，右键 →「打开」不一定有效，用「仍要打开」最稳。

终端替代方案（仅在确认下载来自上面的官方 Release 且文件完整时使用）：

```bash
xattr -dr com.apple.quarantine /Applications/DayProgress.app
```

> 这会移除 App 的隔离标记，相当于跳过 Gatekeeper 检查。装在 `~/Applications` 就把路径换成对应的；不要对来路不明的 App 使用。

### 装好之后

DayProgress 是纯菜单栏 App（`LSUIElement`），没有 Dock 图标。第一次启动会有一个一次性的欢迎窗口，关掉它，App 会继续常驻在屏幕右上角菜单栏。

- **打开面板**：点菜单栏的沙漏图标。
- **退出**：点菜单栏图标 → 面板底部右侧的「退出」；浮窗右键菜单里也有「退出 DayProgress」。

### 登录时启动

在设置里打开「登录时启动」后，可能需要到 **「系统设置 → 通用 → 登录项」** 允许 DayProgress。App 使用 ad-hoc 签名，个别 macOS 版本可能拒绝注册；如果开关报错，先把 App 放到 `/Applications` 再试，或在「登录项」里手动添加。

### 卸载

1. 如果开过「登录时启动」，先在设置里关掉；如果 App 已经删了，去「系统设置 → 通用 → 登录项」里移除残留项。
2. 从菜单栏面板底部点「退出」。
3. 把 `/Applications/DayProgress.app`（或 `~/Applications/DayProgress.app`）拖进废纸篓。
4. 想连设置一起清掉，可选：`defaults delete com.tree.dayprogress`（提示 domain 不存在就说明本来没存过）。

### 遇到问题

- **双击后什么都没看到，或菜单栏图标不见了？** 它没有 Dock 图标或主窗口，先看屏幕右上角菜单栏；图标可能被刘海或 Bartender / Ice 之类的菜单栏工具藏起来。也可以先退出再重新打开。
- **提示「无法验证开发者」或「已损坏」？** 按上面的 Gatekeeper 步骤点「仍要打开」。只有确认下载源是官方 Release 时，才用 `xattr` 命令。
- **启动闪退或架构不对？** 官方 Release 是通用二进制；自己编译的话用 `UNIVERSAL=1 ./build.sh` 打发布版。检查架构：`lipo -archs /Applications/DayProgress.app/Contents/MacOS/DayProgress`，应包含 `arm64` 和 `x86_64`。
- **「登录时启动」打不开？** 先把 App 放进「应用程序」，再到「系统设置 → 通用 → 登录项」允许；ad-hoc 签名在个别系统上可能注册失败。

## 为什么做这个

在 X 上看到一句话：**24 分钟，就是你一天的 1/60。**

一天 1440 分钟，24 分钟刚好是 1/60，也就是 1.67%。一天里能有几个这样的 24 分钟？刷一会儿手机就没了。

于是我用 **DeepSeek-V4-Flash-1017** 写了这个小工具。它不管理你的时间，只是让时间变得可见：抬头看一眼菜单栏，就知道今天溜走了多少。

## 长什么样

菜单栏 + 桌面浮窗：

![菜单栏下拉面板](docs/popover.png)

![桌面浮窗](docs/floating-card.png)

设置页（面板右上角齿轮）：

![设置页](docs/popover-settings.png)

中英文实时切换：

![English panel](docs/popover-en.png)

进度模式切成“还剩多少”，环和数字一起反向：

![剩余模式浮窗](docs/floating-card-remaining.png)

三档尺寸 + 深色 / 毛玻璃 / 透明三种外观：

![中号浮窗](docs/floating-card-medium.png)

![小号浮窗](docs/floating-card-mini.png)

毛玻璃效果（真实截图）：

![毛玻璃浮窗](docs/floating-card-glass.png)

透明效果（真实截图）：

![透明浮窗](docs/floating-card-plain.png)

## 功能

- **实时百分比**：菜单栏常驻（如 `⏳ 79.0%`），点开是完整面板。
- **桌面浮窗**：环形进度 + 大号百分比 + 剩余时间；置顶、可拖动、位置记住，右击可隐藏。
- **只保留菜单栏**：不想要桌面浮窗时，在设置里切换成「仅菜单栏」，桌面上就只剩菜单栏的百分比。
- **进度模式**：已过 / 剩余，24 格“一天刻度环”会跟着反向点亮。
- **中 / 英文界面**：设置里一键切换，日期、文案、浮窗内容一起变。
- **更多时区**：跟随系统 + 19 个常用时区（上海、东京、伦敦、纽约、洛杉矶…），标题旁显示时区徽标与 UTC 偏移。
- **计日方式**：自然日（00:00–24:00）或自定义时段（如 07:00–23:00，支持跨夜）。
- **百分比精度**：整数（`77%`）或一位小数（`77.8%`）。
- **浮窗尺寸 / 外观**：大 / 中 / 小 × 深色 / 毛玻璃 / 透明。
- **登录时启动**、所有设置自动保存。
- 每 10 秒检查时间；菜单栏文字仅在内容变化时更新，唤醒或系统时间变化后立即同步。

## 从源码构建

要求：macOS 13+，已安装 Xcode 或 Command Line Tools（`swiftc` 可用）。

```bash
git clone https://github.com/ACGpp/DayProgress.git
cd DayProgress

./build.sh            # 当前架构，快
UNIVERSAL=1 ./build.sh  # arm64 + x86_64 通用二进制
./install.sh          # 复制到「应用程序」并启动
./test.sh             # 时间、刷新和浮窗生命周期回归检查
./release.sh          # 通用版 DMG + ZIP + SHA256SUMS.txt，输出到 dist/
```

也可以直接运行：`open build/DayProgress.app`。

CI 在 GitHub Actions 上跑（见 `.github/workflows/build.yml`），打 `v*` tag 时自动发布 Release（`.github/workflows/release.yml`）。

## 开发

```
DayProgress/
├── Sources/
│   ├── DayProgressApp.swift   # 菜单栏入口
│   ├── MenuBarLabel.swift     # 按显示变化更新菜单栏
│   ├── AppDelegate.swift      # 桌面浮窗（NSPanel）管理：尺寸、样式、位置
│   ├── DayClock.swift         # 计时、时区、百分比、本地化文案
│   ├── Localization.swift     # 语言 / 进度模式 / 精度 / 时区选项
│   ├── DayRing.swift          # 平滑进度环 + 24 格刻度环 + 配色
│   ├── FloatingCardView.swift # 浮窗界面（三档尺寸 × 三种外观）
│   ├── PopoverView.swift      # 下拉面板：主页 + 设置页
│   └── LoginItem.swift        # 登录启动（SMAppService）
├── Tests/                     # regression checks
├── packaging/                 # bilingual installation guides
├── Tools/MemoryProbe/         # reproducible allocation comparison
├── Tools/MakePreview/         # 离屏渲染预览图与 App 图标（开发用）
├── docs/                      # README 截图与图标
├── build.sh                   # 构建 App
├── preview.sh                 # 渲染预览图 + 图标
├── release.sh                 # 打发布包
└── install.sh                 # 安装到「应用程序」
```

改界面时想快速看效果：

```bash
./preview.sh   # 输出 build/preview/card-*.png、popover-*.png 和 build/AppIcon.png
```

想看真实面板的渲染（会额外打开一个无边框窗口，方便截图）：

```bash
DAYPROGRESS_DEBUG_POPOVER=1 ./build/DayProgress.app/Contents/MacOS/DayProgress          # 主页
DAYPROGRESS_DEBUG_POPOVER=settings ./build/DayProgress.app/Contents/MacOS/DayProgress   # 设置页
```

### 已知限制

- App 未公证，仅适合自用；首次打开可能需要手动放行（见上面的「第一次打开」）。
- 「登录时启动」需要 App 位于「应用程序」文件夹，且可能需要在「系统设置 → 通用 → 登录项」里允许。
- 语言 / 时区等设置只存在本机 `com.tree.dayprogress` 的 UserDefaults 里，不上传任何数据。

## 致谢

- 灵感来自 X 上关于“24 分钟 = 一天的 1/60”的帖子。
- 全程与 **DeepSeek-V4-Flash-1017** 结对完成，从想法到可安装的 Mac App 只花了一个下午。
- 界面、图标由 SwiftUI 绘制。

如果它让你多看了几眼时间，欢迎点个 Star ⭐️

## License

[MIT](LICENSE) © 2026 ACGpp
