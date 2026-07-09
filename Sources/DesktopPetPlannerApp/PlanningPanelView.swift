import PetPlannerCore
import SwiftUI

struct PlanningPanelView: View {
    @EnvironmentObject private var viewModel: PlannerViewModel

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
        .alert("Planner Notice", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Desktop Pet Planner")
                    .font(.title2.bold())
                Text("Capture interrupted work and keep the important few visible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Shown \(viewModel.pinnedTasks.count) / Today \(viewModel.tasks.count)")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
        }
    }

    private var quickInput: some View {
        HStack(spacing: 10) {
            TextField("Try: 20分钟后提醒我看 Cursor 报错 / 下午2点前确认报价，紧急", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.addTask()
                }
            Button("Add") {
                viewModel.addTask()
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
    }

    private var pinnedStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Desktop Visible")
                .font(.headline)
            if viewModel.pinnedTasks.isEmpty {
                Text("Pinned urgent or waiting tasks will appear here.")
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
        Picker("Filter", selection: $viewModel.selectedFilter) {
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
                Text("No tasks in this view.")
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
                StatusBadge(text: task.status.rawValue.capitalized, isUrgent: task.priority == .urgent)
                Spacer()
                if task.priority == .urgent {
                    Text("Urgent")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
            Text(task.title)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
            if let remindAt = task.remindAt {
                Text(remindAt, style: .time)
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
                    StatusBadge(text: task.status.rawValue.capitalized, isUrgent: task.priority == .urgent)
                    if task.isPinned {
                        StatusBadge(text: "Pinned", isUrgent: false)
                    }
                    if let remindAt = task.remindAt {
                        Text("Remind \(remindAt, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(task.isPinned ? "Unpin" : "Pin") {
                viewModel.togglePin(task)
            }
            Button("Wait") {
                viewModel.markWaiting(task)
            }
            Button("Later") {
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
