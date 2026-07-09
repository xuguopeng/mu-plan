import Foundation
import Testing
@testable import PetPlannerCore

@Suite("TaskParser")
struct TaskParserTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        return calendar
    }()

    @Test("parses Chinese relative reminder")
    func parsesChineseRelativeReminder() throws {
        let now = try date(year: 2026, month: 7, day: 9, hour: 11, minute: 0)
        let parser = TaskParser(calendar: calendar)

        let parsed = parser.parse("20分钟后提醒我看 Cursor 报错", now: now)

        #expect(parsed.status == .waiting)
        #expect(parsed.isPinned)
        #expect(parsed.remindAt == calendar.date(byAdding: .minute, value: 20, to: now))
    }

    @Test("parses Chinese urgent absolute time")
    func parsesChineseUrgentAbsoluteTime() throws {
        let now = try date(year: 2026, month: 7, day: 9, hour: 11, minute: 0)
        let parser = TaskParser(calendar: calendar)

        let parsed = parser.parse("下午2点前确认报价，紧急", now: now)
        let expectedDueAt = try date(year: 2026, month: 7, day: 9, hour: 14, minute: 0)

        #expect(parsed.priority == .urgent)
        #expect(parsed.isPinned)
        #expect(parsed.dueAt == expectedDueAt)
        #expect(parsed.remindAt == parsed.dueAt)
    }

    @Test("waiting task without explicit time has no reminder")
    func waitingTaskWithoutExplicitTimeHasNoReminder() throws {
        let now = try date(year: 2026, month: 7, day: 9, hour: 11, minute: 0)
        let parser = TaskParser(calendar: calendar, defaultWaitingReminderMinutes: 25)

        let parsed = parser.parse("等 AI 跑完后继续改样式", now: now)

        #expect(parsed.status == .waiting)
        #expect(parsed.isPinned)
        #expect(parsed.remindAt == nil)
    }

    @Test("plain task still saves as active")
    func plainTaskStillSavesAsActive() throws {
        let now = try date(year: 2026, month: 7, day: 9, hour: 11, minute: 0)
        let parser = TaskParser(calendar: calendar)

        let parsed = parser.parse("整理今天的录音", now: now)

        #expect(parsed.status == .active)
        #expect(parsed.priority == .normal)
        #expect(!parsed.isPinned)
        #expect(parsed.remindAt == nil)
    }

    @Test("ordinary content time is not parsed as reminder")
    func ordinaryContentTimeIsNotParsedAsReminder() throws {
        let now = try date(year: 2026, month: 7, day: 9, hour: 11, minute: 0)
        let parser = TaskParser(calendar: calendar)

        let parsed = parser.parse("每天晚上 8 点发小说，一个小说发 5 篇。", now: now)

        #expect(parsed.status == .active)
        #expect(parsed.dueAt == nil)
        #expect(parsed.remindAt == nil)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try #require(components.date)
    }
}
