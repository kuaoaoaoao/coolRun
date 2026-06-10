# coolRun

coolRun 是一款 macOS 菜单栏系统监控小工具。它把 CPU、内存、储存、电池、网络状态和浙商银行积存金价格放在菜单栏里，适合日常轻量查看电脑状态和实时金价。

应用默认常驻菜单栏，不显示 Dock 图标。菜单栏中会显示一个金币图标和当前金价，点击图标可以展开系统监控面板，右键可以打开设置或退出程序。

## 功能特性

- 菜单栏常驻显示
  - 使用 `NSStatusItem` 常驻 macOS 菜单栏。
  - 菜单栏标题显示浙商银行积存金价格，格式为 `¥xxx.xx/g`。
  - 金币图标会持续旋转，CPU 占用越高，旋转速度越快。

- 系统监控面板
  - CPU：显示核心数、实时占用百分比和动态柱状条。
  - 内存：显示已用内存、物理内存总量和内存压力。
  - 储存：显示磁盘已用、可用空间和使用进度。
  - 电池：显示电量、充电状态和低电量模式状态。
  - 网络：显示连接状态、本地 IP 和活动网络接口数量。

- 金价查询
  - 使用浙商银行积存金公开接口查询金价。
  - 当前接口：

    ```text
    https://api.jdjygold.com/gw2/generic/produTools/h5/m/getGoldPrice?goldCode=CZB-JCJ
    ```

  - 读取返回数据中的 `resultData.data.lastPrice`，按人民币/克展示。
  - 当前刷新间隔在 `MacAppDelegate.swift` 中配置，默认是每秒刷新一次。

- 设置界面
  - 关于：展示应用名称、作者、GitHub 地址和当前版本。
  - 版本更新：提供检查更新入口。

- 版本更新
  - 设置页保留“版本更新”入口。
  - 当前未启用自动更新，后续版本可以通过 GitHub Releases 手动下载安装。

## 运行环境

- macOS
- Xcode 15 或更高版本
- Swift / SwiftUI
- Swift Package Manager

## 项目结构

```text
coolRun
├── coolRun.xcodeproj
├── coolRun
│   ├── coolRunApp.swift
│   ├── MacAppDelegate.swift
│   ├── ContentView.swift
│   ├── MenuBarMonitorView.swift
│   ├── SettingsView.swift
│   ├── GoldPriceService.swift
│   ├── SystemMonitorViewModel.swift
│   ├── SystemSampler.swift
│   ├── SystemMetrics.swift
│   ├── AppVersion.swift
│   ├── coolRun.entitlements
│   └── Assets.xcassets
├── scripts/
│   └── create-dmg.sh
├── SPARKLE_SETUP.md
└── README.md
```

主要文件说明：

- `coolRunApp.swift`：应用入口，macOS 下注册 `MacAppDelegate`，并提供设置窗口。
- `MacAppDelegate.swift`：菜单栏图标、金币动画、弹出面板、右键菜单和金价刷新逻辑。
- `ContentView.swift`：系统监控面板 UI。
- `MenuBarMonitorView.swift`：菜单栏弹出窗口中的监控视图。
- `SettingsView.swift`：设置窗口，包括关于和版本更新。
- `GoldPriceService.swift`：浙商银行积存金价格请求与解析。
- `SystemSampler.swift`：CPU、内存、储存、电池和网络数据采样。
- `SystemMonitorViewModel.swift`：每秒刷新系统监控快照。
- `SPARKLE_SETUP.md`：如果后续重新接入 Sparkle，可参考其中的配置、签名和 appcast 发布说明。

## 使用方式

1. 使用 Xcode 打开项目根目录下的 `coolRun.xcodeproj`。
2. 等待 Xcode 解析 Swift Package 依赖。
3. 选择 `coolRun` scheme。
4. 运行目标选择 `My Mac`。
5. 点击运行后，应用会出现在 macOS 菜单栏。

菜单栏操作：

- 左键点击金币图标：显示或隐藏系统监控面板。
- 点击其他地方：监控面板会自动隐藏。
- 右键点击金币图标：打开菜单，可以选择“设置”或“退出程序”。

## 金价接口说明

当前金价来源是浙商银行积存金接口：

```text
https://api.jdjygold.com/gw2/generic/produTools/h5/m/getGoldPrice?goldCode=CZB-JCJ
```

示例返回中会包含：

```json
{
  "resultData": {
    "data": {
      "name": "浙商银行积存金",
      "lastPrice": 973.24
    }
  }
}
```

应用会读取 `lastPrice` 并显示为：

```text
¥973.24/g
```

如果请求失败，菜单栏会显示类似 `金价网络失败`、`金价解析失败` 的提示。

## 版本更新说明

当前项目已经移除 Sparkle 自动更新依赖，避免因为 GitHub 网络问题导致 Xcode 无法解析依赖、项目无法运行。

现阶段推荐使用 GitHub Releases 手动发布新版本：

1. 提高 Xcode 中的版本号。
2. Archive 并导出应用。
3. 制作 `.dmg` 或 `.zip` 安装包。
4. 在 GitHub 创建新的 Release 和 Tag。
5. 上传安装包。

如果后续需要重新接入 Sparkle，可以参考 [SPARKLE_SETUP.md](./SPARKLE_SETUP.md)。

## 打包发布

### 1. 使用 Xcode 导出 App

1. 打开 `coolRun.xcodeproj`。
2. 顶部运行目标选择 **My Mac**。
3. 菜单栏选择 **Product > Archive**，等待 Archive 完成。
4. 在弹出的 **Organizer** 窗口中，选中刚生成的 Archive。
5. 点击 **Distribute App**。
6. 如果只是本地使用或发给朋友，选择 **Copy App** 或 **Export** 的本地导出方式（不需要上架 App Store）。
7. 导出后得到 `coolRun.app`。

### 2. 制作 DMG 安装包

假设 `coolRun.app` 已导出到桌面，打开终端执行：

```bash
cd /Users/kuao/Desktop

mkdir -p coolRun-dmg
cp -R coolRun.app coolRun-dmg/
ln -s /Applications coolRun-dmg/Applications

hdiutil create \
  -volname "coolRun" \
  -srcfolder coolRun-dmg \
  -ov \
  -format UDZO \
  coolRun.dmg

rm -rf coolRun-dmg
```

最终得到 `/Users/kuao/Desktop/coolRun.dmg`，把这个文件发给朋友即可。

> **提示**：朋友双击 DMG 后，将 `coolRun.app` 拖入 `Applications` 文件夹即可完成安装。

### 3. 发布到 GitHub

1. 提高 Xcode 中的版本号。
2. 在 GitHub 创建新的 Release 和 Tag，例如 `v1.0.1`。
3. 上传 DMG 文件，例如 `coolRun-1.0.1.dmg`。

### 4. 关于代码签名

当前项目未配置 Apple Developer 代码签名。朋友打开时如果提示"无法验证开发者"，解决方式：

- **临时方式**：右键点击 `coolRun.app`，选择 **打开**，在弹窗中确认即可。
- **完全正常双击打开**：需要注册 Apple Developer 账号，配置代码签名和 **Notarization**（公证）。参考 [Apple 官方文档](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)。

## 注意事项

- 当前应用是菜单栏工具，默认不会在 Dock 中显示主窗口。
- 金价接口是第三方公开接口，稳定性取决于接口提供方。
- 当前金价刷新频率较高，如果接口发生限频，可以在 `MacAppDelegate.swift` 中调整 `goldPriceRefreshInterval`。

## 作者

- 作者：kuao
- GitHub：github.com/kuaoaoaoao/coolRun
