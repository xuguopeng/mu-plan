import Foundation

public struct ParsedTask: Equatable, Sendable {
    public var title: String
    public var rawText: String
    public var status: TaskStatus
    public var priority: TaskPriority
    public var isPinned: Bool
    public var dueAt: Date?
    public var remindAt: Date?

    public init(
        title: String,
        rawText: String,
        status: TaskStatus,
        priority: TaskPriority,
        isPinned: Bool,
        dueAt: Date?,
        remindAt: Date?
    ) {
        self.title = title
        self.rawText = rawText
        self.status = status
        self.priority = priority
        self.isPinned = isPinned
        self.dueAt = dueAt
        self.remindAt = remindAt
    }
}

public struct TaskParser: Sendable {
    public var calendar: Calendar
    public var defaultWaitingReminderMinutes: Int

    public init(calendar: Calendar = .current, defaultWaitingReminderMinutes: Int = 20) {
        self.calendar = calendar
        self.defaultWaitingReminderMinutes = defaultWaitingReminderMinutes
    }

    public func parse(_ text: String, now: Date = Date()) -> ParsedTask {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        let isWaiting = containsAny(normalized, [
            "wait", "waiting", "finish", "ai", "cursor", "claude",
            "等ai", "等 ai", "等cursor", "等 cursor", "等claude", "等 claude",
            "跑完", "结束", "完成"
        ])
        let isUrgent = containsAny(normalized, [
            "urgent", "important", "before", "紧急", "重要", "截止", "之前", "前"
        ])
        let relativeReminder = parseRelativeReminder(normalized, now: now)
        let absoluteTime = parseAbsoluteTime(normalized, now: now)
        let reminder: Date?
        if let relativeReminder {
            reminder = relativeReminder
        } else if let absoluteTime {
            reminder = absoluteTime
        } else if isWaiting {
            reminder = calendar.date(byAdding: .minute, value: defaultWaitingReminderMinutes, to: now)
        } else {
            reminder = nil
        }

        let status: TaskStatus = isWaiting ? .waiting : .active
        return ParsedTask(
            title: trimmed.isEmpty ? "Untitled Task" : trimmed,
            rawText: text,
            status: status,
            priority: isUrgent ? .urgent : .normal,
            isPinned: isUrgent || isWaiting,
            dueAt: absoluteTime,
            remindAt: reminder
        )
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private func parseRelativeReminder(_ text: String, now: Date) -> Date? {
        if text.contains("半小时后") {
            return calendar.date(byAdding: .minute, value: 30, to: now)
        }
        if text.contains("一小时后") || text.contains("1小时后") {
            return calendar.date(byAdding: .hour, value: 1, to: now)
        }

        if let minutes = firstMatchInt(in: text, pattern: #"(\d+)\s*(minutes?|mins?|分钟)\s*(later|后)?"#) {
            return calendar.date(byAdding: .minute, value: minutes, to: now)
        }
        if let minutes = firstMatchInt(in: text, pattern: #"(in|after)\s*(\d+)\s*(minutes?|mins?)"#, captureGroup: 2) {
            return calendar.date(byAdding: .minute, value: minutes, to: now)
        }
        if let hours = firstMatchInt(in: text, pattern: #"(\d+)\s*(hours?|小时)\s*(later|后)?"#) {
            return calendar.date(byAdding: .hour, value: hours, to: now)
        }
        if let hours = firstMatchInt(in: text, pattern: #"(in|after)\s*(\d+)\s*(hours?)"#, captureGroup: 2) {
            return calendar.date(byAdding: .hour, value: hours, to: now)
        }
        return nil
    }

    private func parseAbsoluteTime(_ text: String, now: Date) -> Date? {
        let targetDayOffset = text.contains("tomorrow") || text.contains("明天") ? 1 : 0
        let day = calendar.date(byAdding: .day, value: targetDayOffset, to: calendar.startOfDay(for: now)) ?? now

        if let match = firstTimeMatch(in: text, pattern: #"(\d{1,2}):(\d{2})"#) {
            return date(on: day, hour: match.hour, minute: match.minute)
        }
        if let hour = firstMatchInt(in: text, pattern: #"(\d{1,2})\s*(pm)"#) {
            return date(on: day, hour: normalizedHour(hour, isPM: true), minute: 0)
        }
        if let hour = firstMatchInt(in: text, pattern: #"(\d{1,2})\s*(am)"#) {
            return date(on: day, hour: normalizedHour(hour, isPM: false), minute: 0)
        }
        if let hour = firstMatchInt(in: text, pattern: #"下午\s*(\d{1,2})\s*点"#) {
            return date(on: day, hour: normalizedHour(hour, isPM: true), minute: 0)
        }
        if let hour = firstMatchInt(in: text, pattern: #"上午\s*(\d{1,2})\s*点"#) {
            return date(on: day, hour: normalizedHour(hour, isPM: false), minute: 0)
        }
        if let hour = firstMatchInt(in: text, pattern: #"(\d{1,2})\s*点\s*前?"#) {
            return date(on: day, hour: hour, minute: 0)
        }
        return nil
    }

    private func normalizedHour(_ hour: Int, isPM: Bool) -> Int {
        if isPM, hour < 12 {
            return hour + 12
        }
        if !isPM, hour == 12 {
            return 0
        }
        return hour
    }

    private func date(on day: Date, hour: Int, minute: Int) -> Date? {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    private func firstMatchInt(in text: String, pattern: String, captureGroup: Int = 1) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              captureGroup < match.numberOfRanges,
              let swiftRange = Range(match.range(at: captureGroup), in: text)
        else {
            return nil
        }
        return Int(text[swiftRange])
    }

    private func firstTimeMatch(in text: String, pattern: String) -> (hour: Int, minute: Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 3,
              let hourRange = Range(match.range(at: 1), in: text),
              let minuteRange = Range(match.range(at: 2), in: text),
              let hour = Int(text[hourRange]),
              let minute = Int(text[minuteRange])
        else {
            return nil
        }
        return (hour, minute)
    }
}
