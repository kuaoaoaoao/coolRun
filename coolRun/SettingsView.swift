import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 顶部 Header
            headerSection

            Divider()
                .padding(.horizontal, 20)

            // 内容区域
            ScrollView {
                VStack(spacing: 16) {
                    infoCard
                    linksCard
                }
                .padding(20)
            }
        }
        .frame(width: 420, height: 380)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            // App Icon with shadow
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text("coolRun")
                    .font(.title.weight(.bold))

                Text("菜单栏系统监控 · 实时金价")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("v\(AppVersion.current.displayText)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "person.fill", label: "作者", value: "kuaoaoaoao")
            Divider().padding(.horizontal, 12)
            SettingsRow(icon: "tag.fill", label: "版本", value: AppVersion.current.displayText)
            Divider().padding(.horizontal, 12)
            SettingsRow(icon: "hammer.fill", label: "Swift", value: "SwiftUI + AppKit")
            Divider().padding(.horizontal, 12)
            SettingsRow(icon: "desktopcomputer", label: "平台", value: "macOS 15.0+")
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Links Card

    private var linksCard: some View {
        VStack(spacing: 0) {
            LinkRow(
                icon: "globe",
                label: "项目主页",
                url: AppLinks.repository
            )
            Divider().padding(.horizontal, 12)
            LinkRow(
                icon: "arrow.down.circle.fill",
                label: "检查更新",
                url: AppLinks.releases
            )
//            Divider().padding(.horizontal, 12)
//            LinkRow(
//                icon: "star.fill",
//                label: "GitHub Releases",
//                url: AppLinks.releases
//            )
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white.opacity(0.8)
    }

    private var cardBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }
}

// MARK: - Components

private struct SettingsRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct LinkRow: View {
    let icon: String
    let label: String
    let url: URL

    @Environment(\.openURL) private var openURL
    @State private var isHovering = false

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.accentColor.opacity(0.08) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .cursor(.pointingHand)
    }
}

// MARK: - Cursor Modifier

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Data

private enum AppLinks {
    static let repository = URL(string: "https://github.com/kuaoaoaoao/coolRun")!
    static let releases = URL(string: "https://github.com/kuaoaoaoao/coolRun/releases")!
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
