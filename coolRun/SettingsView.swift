import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AboutSettingsView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }

            UpdateSettingsView()
                .tabItem {
                    Label("版本更新", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .frame(width: 500, height: 360)
        .padding(18)
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderView(
                title: "coolRun",
                subtitle: "系统监控与浙商积存金价格菜单栏工具"
            )

            SettingsGroup {
                SettingsInfoRow(label: "作者", value: "kuao")
                SettingsLinkRow(
                    label: "GitHub",
                    title: "github.com/kuaoaoaoao/coolRun",
                    url: AppLinks.repository
                )
                SettingsInfoRow(label: "当前版本", value: AppVersion.current.displayText)
            }

            SettingsGroup {
                SettingsDescriptionRow(
                    icon: "menubar.rectangle",
                    title: "菜单栏常驻",
                    detail: "显示金币动画、实时金价，并可展开系统监控面板。"
                )
                SettingsDescriptionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "系统状态",
                    detail: "查看 CPU、内存、储存、电池和网络状态。"
                )
            }

            Spacer()
        }
        .padding(8)
    }
}

private struct UpdateSettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderView(
                title: "版本更新",
                subtitle: "当前未启用自动更新，可以前往 GitHub Releases 手动下载新版本。"
            )

            SettingsGroup {
                SettingsInfoRow(label: "当前版本", value: AppVersion.current.displayText)
                SettingsLinkRow(
                    label: "下载地址",
                    title: "打开 GitHub Releases",
                    url: AppLinks.releases
                )
            }

            SettingsGroup {
                SettingsDescriptionRow(
                    icon: "1.circle",
                    title: "下载新版安装包",
                    detail: "进入 Releases 页面，下载最新的 dmg 或 zip 文件。"
                )
                SettingsDescriptionRow(
                    icon: "2.circle",
                    title: "替换旧版本",
                    detail: "退出当前应用后，将新版本拖入 Applications 并覆盖旧版本。"
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    openURL(AppLinks.releases)
                } label: {
                    Label("前往下载", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(8)
    }
}

private struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            if title == "coolRun" {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 54))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .frame(width: 58, height: 58)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
        }
    }
}

private struct SettingsDescriptionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}

private struct SettingsLinkRow: View {
    let label: String
    let title: String
    let url: URL

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Link(destination: url) {
                Label(title, systemImage: "arrow.up.right.square")
                    .labelStyle(.titleAndIcon)
            }
            .help(url.absoluteString)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}

private enum AppLinks {
    static let repository = URL(string: "https://github.com/kuaoaoaoao/coolRun")!
    static let releases = URL(string: "https://github.com/kuaoaoaoao/coolRun/releases")!
}
