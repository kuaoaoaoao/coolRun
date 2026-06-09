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
        .frame(width: 420, height: 300)
        .padding(16)
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("coolRun")
                        .font(.title2.weight(.semibold))
                    Text("系统监控与浙商积存金价格菜单栏工具")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            SettingsInfoRow(label: "作者", value: "kuao")
            SettingsInfoRow(label: "GitHub", value: "github.com/kuaoaoaoao/coolRun")
            SettingsInfoRow(label: "当前版本", value: AppVersion.current.displayText)

            Spacer()
        }
        .padding(8)
    }
}

private struct UpdateSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("版本更新")
                    .font(.title2.weight(.semibold))
                Text("使用 Sparkle 检查、下载并安装新版本。")
                    .foregroundStyle(.secondary)
            }

            Divider()

            SettingsInfoRow(label: "当前版本", value: AppVersion.current.displayText)
            SettingsInfoRow(label: "更新源", value: "GitHub Releases Appcast")
            Text("发布新版本时，需要同步更新 Sparkle appcast，并使用 Sparkle 私钥签名安装包。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Spacer()

            HStack {
                Button {
                    #if os(macOS)
                    SparkleUpdater.shared.checkForUpdates()
                    #endif
                } label: {
                    Label("检查更新", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .padding(8)
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
