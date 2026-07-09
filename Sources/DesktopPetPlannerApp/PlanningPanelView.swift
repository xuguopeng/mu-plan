import PetPlannerCore
import SwiftUI

struct PlanningPanelView: View {
    @EnvironmentObject private var viewModel: PlannerViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            quickInput
            pinnedStrip
            filterPicker
            taskList
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(WindowFrontmostConfigurator())
        .background(PetWindowPresenter(viewModel: viewModel))
        .onAppear {
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
        .alert("提示", isPresented: errorBinding) {
            Button("好", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("桌面计划宠物")
                    .font(.title2.bold())
                Text("把被打断的事情先放住，让最重要的几件一直可见。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("显示 \(viewModel.pinnedTasks.count) / 今天 \(viewModel.tasks.count)")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
        }
    }

    private var quickInput: some View {
        HStack(spacing: 10) {
            TextField("例如：20分钟后提醒我看 Cursor 报错 / 下午2点前确认报价，紧急", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.addTask()
                }
            Button("添加") {
                viewModel.addTask()
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
    }

    private var pinnedStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("桌面显示")
                .font(.headline)
            if viewModel.pinnedTasks.isEmpty {
                Text("钉住的紧急事项或等待事项会显示在这里。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.pinnedTasks) { task in
                        PinnedTaskCard(task: task)
                    }
                }
            }
        }
    }

    private var filterPicker: some View {
        Picker("筛选", selection: $viewModel.selectedFilter) {
            ForEach(TaskFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                TaskRow(task: task)
                    .environmentObject(viewModel)
            }
        }
        .listStyle(.inset)
        .overlay {
            if viewModel.filteredTasks.isEmpty {
                Text("这个视图里还没有任务。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct PinnedTaskCard: View {
    let task: PlannerTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                StatusBadge(text: task.status.localizedTitle, isUrgent: task.priority == .urgent)
                Spacer()
                if task.priority == .urgent {
                    Text("紧急")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
            Text(task.title)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
            if let displayTime = task.displayTime {
                Text(displayTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TaskRow: View {
    @EnvironmentObject private var viewModel: PlannerViewModel
    let task: PlannerTask

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                viewModel.complete(task)
            } label: {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body.weight(task.priority == .urgent ? .semibold : .regular))
                    .strikethrough(task.status == .done)
                HStack(spacing: 6) {
                    StatusBadge(text: task.status.localizedTitle, isUrgent: task.priority == .urgent)
                    if task.isPinned {
                        StatusBadge(text: "已钉住", isUrgent: false)
                    }
                    if let displayTime = task.displayTime {
                        Text("提醒 \(displayTime, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(task.isPinned ? "取消显示" : "显示") {
                viewModel.togglePin(task)
            }
            Button("等待") {
                viewModel.markWaiting(task)
            }
            Button("稍后") {
                viewModel.postpone(task)
            }
            Button(role: .destructive) {
                viewModel.delete(task)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

private struct PetWindowPresenter: NSViewRepresentable {
    @ObservedObject var viewModel: PlannerViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.showPanel(viewModel: viewModel)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.update(viewModel: viewModel)
        }
    }

    final class Coordinator {
        private var panel: NSPanel?
        private var hostingView: NSHostingView<AnyView>?

        @MainActor
        func showPanel(viewModel: PlannerViewModel) {
            if panel == nil {
                let hostingView = NSHostingView(rootView: AnyView(PetWidgetView().environmentObject(viewModel)))
                let panel = NSPanel(
                    contentRect: NSRect(x: 80, y: 520, width: 280, height: 260),
                    styleMask: [.nonactivatingPanel, .borderless],
                    backing: .buffered,
                    defer: false
                )
                panel.contentView = hostingView
                panel.isReleasedWhenClosed = false
                panel.isMovableByWindowBackground = true
                panel.backgroundColor = .clear
                panel.isOpaque = false
                panel.hasShadow = true
                panel.level = .floating
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                panel.orderFrontRegardless()
                self.hostingView = hostingView
                self.panel = panel
            }
            update(viewModel: viewModel)
        }

        @MainActor
        func update(viewModel: PlannerViewModel) {
            guard let panel else {
                showPanel(viewModel: viewModel)
                return
            }
            hostingView?.rootView = AnyView(PetWidgetView().environmentObject(viewModel))
            panel.orderFrontRegardless()
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let isUrgent: Bool

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(isUrgent ? .red : .secondary)
            .background(isUrgent ? Color.red.opacity(0.12) : Color.secondary.opacity(0.12), in: Capsule())
    }
}

private struct WindowFrontmostConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window, coordinator: context.coordinator)
        }
    }

    private func configure(window: NSWindow?, coordinator: Coordinator) {
        guard let window else {
            return
        }
        window.level = .floating
        window.collectionBehavior.insert(.canJoinAllSpaces)
        window.delegate = coordinator
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            sender.orderOut(nil)
            return false
        }
    }
}
