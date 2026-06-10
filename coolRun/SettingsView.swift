import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("coolRun")
                        .font(.title2.weight(.semibold))
                    Text("系统监控与浙商积存金价格菜单栏工具")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(label: "作者", value: "kuaoaoaoao")
                InfoRow(label: "版本", value: AppVersion.current.displayText)
                HStack(alignment: .firstTextBaseline) {
                    Text("GitHub")
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .leading)
                    Link(destination: AppLinks.repository) {
                        Text("github.com/kuaoaoaoao/coolRun")
                    }
                    .font(.callout)
                    Spacer(minLength: 0)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()

            HStack {
                Spacer()
                Button {
                    openURL(AppLinks.releases)
                } label: {
                    Label("检查更新", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 400, height: 280)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}

private enum AppLinks {
    static let repository = URL(string: "https://github.com/kuaoaoaoao/coolRun")!
    static let releases = URL(string: "https://github.com/kuaoaoaoao/coolRun/releases")!
}
