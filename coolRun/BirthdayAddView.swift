import SwiftUI
import AppKit

// MARK: - AppKit TextField 包装器（解决 NSPopover 中的输入问题）

struct AppKitTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var font: NSFont = .systemFont(ofSize: 12)
    var onSubmit: (() -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.font = font
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.isEditable = true
        textField.isSelectable = true
        textField.delegate = context.coordinator
        textField.focusRingType = .exterior
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.lineBreakMode = .byTruncatingTail

        // 确保可以输入中文
        textField.allowsEditingTextAttributes = false
        textField.importsGraphics = false

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: AppKitTextField

        init(_ parent: AppKitTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit?()
                return true
            }
            return false
        }
    }
}

// MARK: - 添加/编辑生日视图

struct BirthdayAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let existingBirthday: Birthday?
    let onSave: (Birthday) -> Void

    @State private var name: String = ""
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var isLeapMonth: Bool = false
    @State private var note: String = ""

    private let monthNames = ["正月", "二月", "三月", "四月", "五月", "六月",
                               "七月", "八月", "九月", "十月", "冬月", "腊月"]

    private let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    init(existingBirthday: Birthday? = nil, onSave: @escaping (Birthday) -> Void) {
        self.existingBirthday = existingBirthday
        self.onSave = onSave

        if let birthday = existingBirthday {
            _name = State(initialValue: birthday.name)
            _selectedMonth = State(initialValue: birthday.lunarMonth)
            _selectedDay = State(initialValue: birthday.lunarDay)
            _isLeapMonth = State(initialValue: birthday.isLeapMonth)
            _note = State(initialValue: birthday.note)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()

            // 表单内容
            ScrollView {
                VStack(spacing: 16) {
                    // 姓名输入
                    formField(title: "姓名") {
                        AppKitTextField(text: $name, placeholder: "输入姓名")
                            .frame(height: 24)
                    }

                    // 农历日期选择
                    formField(title: "农历生日") {
                        VStack(spacing: 12) {
                            // 闰月开关
                            Toggle(isOn: $isLeapMonth) {
                                Text("闰月")
                                    .font(.system(size: 12))
                            }
                            .toggleStyle(.switch)
                            .tint(AppTheme.healthy)

                            // 月份选择
                            VStack(alignment: .leading, spacing: 4) {
                                Text("月份")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary(colorScheme))

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                                    ForEach(1...12, id: \.self) { month in
                                        monthButton(month: month)
                                    }
                                }
                            }

                            // 日期选择
                            VStack(alignment: .leading, spacing: 4) {
                                Text("日期")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary(colorScheme))

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                                    ForEach(1...daysInSelectedMonth, id: \.self) { day in
                                        dayButton(day: day)
                                    }
                                }
                            }
                        }
                    }

                    // 备注
                    formField(title: "备注（可选）") {
                        AppKitTextField(text: $note, placeholder: "如：妈妈、朋友")
                            .frame(height: 24)
                    }

                    // 预览
                    previewSection
                }
                .padding(16)
            }

            Divider()

            // 底部按钮
            bottomButtons
        }
        .frame(width: 300, height: 420)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Text(existingBirthday == nil ? "添加生日" : "编辑生日")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 表单字段

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(colorScheme))
            content()
        }
    }

    // MARK: - 月份按钮

    private func monthButton(month: Int) -> some View {
        let isSelected = selectedMonth == month

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedMonth = month
                // 确保日期不超过该月最大天数
                if selectedDay > maxDayForMonth(month) {
                    selectedDay = maxDayForMonth(month)
                }
            }
        }) {
            Text(monthNames[month - 1])
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? AppTheme.healthy : AppTheme.progressBg(colorScheme))
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 日期按钮

    private func dayButton(day: Int) -> some View {
        let isSelected = selectedDay == day

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDay = day
            }
        }) {
            Text(dayNames[day - 1])
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isSelected ? AppTheme.healthy : AppTheme.progressBg(colorScheme))
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 预览

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("预览")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary(colorScheme))

            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name.isEmpty ? "未命名" : name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary(colorScheme))

                    Text(previewDateString)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSecondary(colorScheme))
                }

                Spacer()
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.warning.opacity(0.1))
            }
        }
    }

    // MARK: - 底部按钮

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary(colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.progressBg(colorScheme))
                    }
            }
            .buttonStyle(.plain)

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isValid ? AppTheme.healthy : AppTheme.healthy.opacity(0.5))
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 计算属性

    private var daysInSelectedMonth: Int {
        return maxDayForMonth(selectedMonth)
    }

    private func maxDayForMonth(_ month: Int) -> Int {
        // 农历月份天数：大月30天，小月29天
        // 简化处理：统一使用30天，让用户选择
        return 30
    }

    private var previewDateString: String {
        let monthStr = (isLeapMonth ? "闰" : "") + monthNames[selectedMonth - 1]
        return monthStr + dayNames[selectedDay - 1]
    }

    private var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 保存

    private func save() {
        let birthday = Birthday(
            id: existingBirthday?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            lunarMonth: selectedMonth,
            lunarDay: selectedDay,
            isLeapMonth: isLeapMonth,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(birthday)
        dismiss()
    }
}

// MARK: - 生日列表视图

struct BirthdayListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var birthdays: [Birthday] = []
    @State private var showAddView = false
    @State private var editingBirthday: Birthday?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()

            // 生日列表
            if birthdays.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(birthdays) { birthday in
                        birthdayRow(birthday)
                    }
                    .onDelete(perform: deleteBirthdays)
                }
                .listStyle(.plain)
            }

            Divider()

            // 添加按钮
            addButton
        }
        .frame(width: 300, height: 380)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
        .onAppear {
            loadBirthdays()
        }
        .sheet(isPresented: $showAddView) {
            BirthdayAddView { birthday in
                BirthdayManager.shared.saveBirthday(birthday)
                loadBirthdays()
            }
        }
        .sheet(item: $editingBirthday) { birthday in
            BirthdayAddView(existingBirthday: birthday) { updatedBirthday in
                BirthdayManager.shared.updateBirthday(updatedBirthday)
                loadBirthdays()
            }
        }
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Text("生日管理")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text("\(birthdays.count) 个生日")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary(colorScheme))

            // 关闭按钮
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSecondary(colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 空视图

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textSecondary(colorScheme).opacity(0.5))

            Text("还没有记录生日")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary(colorScheme))

            Text("点击下方按钮添加第一个生日")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary(colorScheme).opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 生日行

    private func birthdayRow(_ birthday: Birthday) -> some View {
        HStack(spacing: 10) {
            // 图标
            Image(systemName: "gift.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.warning)
                .frame(width: 32, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.warning.opacity(0.15))
                }

            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(birthday.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(colorScheme))

                HStack(spacing: 6) {
                    Text(birthday.lunarDateString)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSecondary(colorScheme))

                    if !birthday.note.isEmpty {
                        Text("·")
                            .foregroundStyle(AppTheme.textSecondary(colorScheme).opacity(0.5))

                        Text(birthday.note)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textSecondary(colorScheme))
                    }
                }
            }

            Spacer()

            // 编辑按钮
            Button(action: {
                editingBirthday = birthday
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary(colorScheme))
                    .padding(6)
                    .background {
                        Circle()
                            .fill(AppTheme.progressBg(colorScheme))
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 添加按钮

    private var addButton: some View {
        Button(action: { showAddView = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                Text("添加生日")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(AppTheme.healthy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.healthy.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 方法

    private func loadBirthdays() {
        birthdays = BirthdayManager.shared.getAllBirthdays()
    }

    private func deleteBirthdays(at offsets: IndexSet) {
        for index in offsets {
            BirthdayManager.shared.deleteBirthday(birthdays[index])
        }
        loadBirthdays()
    }
}

// MARK: - 生日详情弹窗

struct BirthdayDetailView: View {
    let birthdays: [Birthday]
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.warning)

                Text("生日提醒")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                // 关闭按钮
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary(colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // 日期信息
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.healthy)

                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textPrimary(colorScheme))

                Spacer()

                Text("农历")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary(colorScheme))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppTheme.progressBg(colorScheme))
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // 生日列表
            ForEach(birthdays) { birthday in
                HStack(spacing: 12) {
                    // 生日图标
                    ZStack {
                        Circle()
                            .fill(AppTheme.warning.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Text("🎂")
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(birthday.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(colorScheme))

                        HStack(spacing: 6) {
                            Text(birthday.lunarDateString)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.warning)

                            if !birthday.note.isEmpty {
                                Text("·")
                                    .foregroundStyle(AppTheme.textSecondary(colorScheme).opacity(0.5))

                                Text(birthday.note)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary(colorScheme))
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.warning.opacity(0.08))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            Spacer()

            // 关闭按钮
            Button(action: { dismiss() }) {
                Text("知道了")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.healthy)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 280)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 预览

struct BirthdayAddView_Previews: PreviewProvider {
    static var previews: some View {
        BirthdayAddView { _ in }
    }
}
