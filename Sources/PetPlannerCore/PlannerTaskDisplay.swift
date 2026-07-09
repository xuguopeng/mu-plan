import Foundation

public extension PlannerTask {
    var displayTime: Date? {
        guard shouldDisplayStoredTime else {
            return nil
        }
        return remindAt ?? dueAt
    }

    private var shouldDisplayStoredTime: Bool {
        let normalized = rawText.lowercased()
        let explicitCueWords = [
            "提醒", "叫我", "到点", "截止", "之前", "前",
            "分钟后", "小时后", "半小时后", "一小时后",
            "later", "after", "in ", "deadline", "remind", "before", "by "
        ]
        return explicitCueWords.contains { normalized.contains($0) }
    }
}
