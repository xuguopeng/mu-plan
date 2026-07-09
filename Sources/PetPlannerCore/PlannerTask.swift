import Foundation

public enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case active
    case waiting
    case later
    case done
}

public enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case normal
    case urgent
}

public enum TaskSource: String, Codable, CaseIterable, Sendable {
    case quickInput
    case panel
}

public struct PlannerTask: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var rawText: String
    public var status: TaskStatus
    public var priority: TaskPriority
    public var isPinned: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var dueAt: Date?
    public var remindAt: Date?
    public var completedAt: Date?
    public var source: TaskSource

    public init(
        id: UUID = UUID(),
        title: String,
        rawText: String,
        status: TaskStatus = .active,
        priority: TaskPriority = .normal,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueAt: Date? = nil,
        remindAt: Date? = nil,
        completedAt: Date? = nil,
        source: TaskSource = .panel
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.status = status
        self.priority = priority
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueAt = dueAt
        self.remindAt = remindAt
        self.completedAt = completedAt
        self.source = source
    }
}
