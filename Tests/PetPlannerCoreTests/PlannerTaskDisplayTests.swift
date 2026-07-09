import Foundation
import Testing
@testable import PetPlannerCore

@Suite("PlannerTask display")
struct PlannerTaskDisplayTests {
    @Test("does not display stored time for ordinary content time")
    func doesNotDisplayStoredTimeForOrdinaryContentTime() {
        let storedTime = Date(timeIntervalSince1970: 100)
        let task = PlannerTask(
            title: "每天晚上 8 点发小说，一个小说发 5 篇。",
            rawText: "每天晚上 8 点发小说，一个小说发 5 篇。",
            remindAt: storedTime
        )

        #expect(task.displayTime == nil)
    }

    @Test("displays time for explicit reminder text")
    func displaysTimeForExplicitReminderText() {
        let storedTime = Date(timeIntervalSince1970: 100)
        let task = PlannerTask(
            title: "20分钟后提醒我看 Cursor 报错",
            rawText: "20分钟后提醒我看 Cursor 报错",
            remindAt: storedTime
        )

        #expect(task.displayTime == storedTime)
    }
}
