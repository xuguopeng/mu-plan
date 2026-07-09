import Foundation
import PetPlannerCore

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published private(set) var tasks: [PlannerTask] = []
    @Published var inputText: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var errorMessage: String?

    private let store: TaskStore
    private var parser: TaskParser

    init(store: TaskStore = TaskStore()) {
        self.store = store
        self.parser = TaskParser()
        do {
            try store.load()
            tasks = store.tasks
            parser = TaskParser(defaultWaitingReminderMinutes: store.settings.defaultWaitingReminderMinutes)
        } catch {
            tasks = store.tasks
            errorMessage = "没有读到原来的任务数据。应用已经备份旧文件，并从空列表开始。"
        }
    }

    var filteredTasks: [PlannerTask] {
        switch selectedFilter {
        case .all:
            return tasks
        case .pinned:
            return tasks.filter { $0.isPinned && $0.status != .done }
        case .waiting:
            return tasks.filter { $0.status == .waiting }
        case .urgent:
            return tasks.filter { $0.priority == .urgent }
        case .done:
            return tasks.filter { $0.status == .done }
        }
    }

    var pinnedTasks: [PlannerTask] {
        store.pinnedTasks
    }

    func addTask() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        let parsed = parser.parse(text)
        do {
            _ = try store.create(from: parsed, source: .panel)
            inputText = ""
            refresh()
        } catch {
            errorMessage = "任务保存失败。"
        }
    }

    func complete(_ task: PlannerTask) {
        perform { try store.complete(task.id) }
    }

    func delete(_ task: PlannerTask) {
        perform { try store.delete(task.id) }
    }

    func togglePin(_ task: PlannerTask) {
        perform {
            if task.isPinned {
                try store.unpin(task.id)
            } else {
                try store.pin(task.id)
            }
        }
    }

    func markWaiting(_ task: PlannerTask) {
        perform { try store.markWaiting(task.id, reminder: task.remindAt) }
    }

    func postpone(_ task: PlannerTask) {
        let reminder = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        perform { try store.postpone(task.id, until: reminder) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            refresh()
        } catch {
            errorMessage = "任务更新失败。"
        }
    }

    private func refresh() {
        tasks = store.tasks
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case pinned = "桌面显示"
    case waiting = "等待中"
    case urgent = "紧急"
    case done = "已完成"

    var id: String { rawValue }
}
