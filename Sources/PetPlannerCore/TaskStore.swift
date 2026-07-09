import Foundation

public struct PlannerSnapshot: Codable, Equatable, Sendable {
    public var tasks: [PlannerTask]
    public var settings: PlannerSettings

    public init(tasks: [PlannerTask] = [], settings: PlannerSettings = PlannerSettings()) {
        self.tasks = tasks
        self.settings = settings
    }
}

public final class TaskStore {
    public private(set) var tasks: [PlannerTask]
    public private(set) var settings: PlannerSettings

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultStoreURL()
        self.tasks = []
        self.settings = PlannerSettings()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            tasks = []
            settings = PlannerSettings()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(PlannerSnapshot.self, from: data)
            tasks = snapshot.tasks
            settings = snapshot.settings
        } catch {
            try preserveCorruptStore()
            tasks = []
            settings = PlannerSettings()
            throw StoreError.loadFailed(error)
        }
    }

    public func save() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let snapshot = PlannerSnapshot(tasks: tasks, settings: settings)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    @discardableResult
    public func create(from parsed: ParsedTask, source: TaskSource = .panel, now: Date = Date()) throws -> PlannerTask {
        let task = PlannerTask(
            title: parsed.title,
            rawText: parsed.rawText,
            status: parsed.status,
            priority: parsed.priority,
            isPinned: parsed.isPinned,
            createdAt: now,
            updatedAt: now,
            dueAt: parsed.dueAt,
            remindAt: parsed.remindAt,
            source: source
        )
        tasks.insert(task, at: 0)
        try save()
        return task
    }

    public func update(_ task: PlannerTask) throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw StoreError.taskNotFound
        }
        var updated = task
        updated.updatedAt = Date()
        tasks[index] = updated
        try save()
    }

    public func complete(_ id: UUID, now: Date = Date()) throws {
        try mutate(id) { task in
            task.status = .done
            task.completedAt = now
            task.updatedAt = now
            task.isPinned = false
        }
    }

    public func delete(_ id: UUID) throws {
        tasks.removeAll { $0.id == id }
        try save()
    }

    public func pin(_ id: UUID) throws {
        try mutate(id) { task in
            task.isPinned = true
        }
    }

    public func unpin(_ id: UUID) throws {
        try mutate(id) { task in
            task.isPinned = false
        }
    }

    public func postpone(_ id: UUID, until date: Date) throws {
        try mutate(id) { task in
            task.status = .later
            task.remindAt = date
        }
    }

    public func markWaiting(_ id: UUID, reminder: Date?) throws {
        try mutate(id) { task in
            task.status = .waiting
            task.remindAt = reminder
            task.isPinned = true
        }
    }

    public func markActive(_ id: UUID) throws {
        try mutate(id) { task in
            task.status = .active
        }
    }

    public func updateSettings(_ settings: PlannerSettings) throws {
        self.settings = settings
        try save()
    }

    public var pinnedTasks: [PlannerTask] {
        tasks
            .filter { $0.isPinned && $0.status != .done }
            .prefix(settings.visiblePinnedTaskCount)
            .map { $0 }
    }

    private func mutate(_ id: UUID, change: (inout PlannerTask) -> Void) throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw StoreError.taskNotFound
        }
        change(&tasks[index])
        tasks[index].updatedAt = Date()
        try save()
    }

    private func preserveCorruptStore() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("planner-corrupt-\(Int(Date().timeIntervalSince1970)).json")
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }

    public static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base
            .appendingPathComponent("DesktopPetPlanner", isDirectory: true)
            .appendingPathComponent("planner.json")
    }
}

public enum StoreError: Error, Equatable {
    case taskNotFound
    case loadFailed(Error)

    public static func == (lhs: StoreError, rhs: StoreError) -> Bool {
        switch (lhs, rhs) {
        case (.taskNotFound, .taskNotFound):
            return true
        case (.loadFailed, .loadFailed):
            return true
        default:
            return false
        }
    }
}
