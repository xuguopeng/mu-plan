import Foundation
import Testing
@testable import PetPlannerCore

@Suite("TaskStore")
struct TaskStoreTests {
    @Test("creates and reloads persisted tasks")
    func createsAndReloadsPersistedTasks() throws {
        let fileURL = temporaryFileURL()
        let store = TaskStore(fileURL: fileURL)
        let parsed = ParsedTask(
            title: "确认报价",
            rawText: "确认报价，紧急",
            status: .active,
            priority: .urgent,
            isPinned: true,
            dueAt: nil,
            remindAt: nil
        )

        let task = try store.create(from: parsed, now: Date(timeIntervalSince1970: 100))

        let reloaded = TaskStore(fileURL: fileURL)
        try reloaded.load()

        #expect(reloaded.tasks.count == 1)
        #expect(reloaded.tasks.first?.id == task.id)
        #expect(reloaded.tasks.first?.title == "确认报价")
        #expect(reloaded.tasks.first?.isPinned == true)
    }

    @Test("completing a task unpins it")
    func completingTaskUnpinsIt() throws {
        let store = TaskStore(fileURL: temporaryFileURL())
        let parsed = ParsedTask(
            title: "等 AI",
            rawText: "等 AI",
            status: .waiting,
            priority: .normal,
            isPinned: true,
            dueAt: nil,
            remindAt: nil
        )
        let task = try store.create(from: parsed)

        try store.complete(task.id)

        #expect(store.tasks.first?.status == .done)
        #expect(store.tasks.first?.isPinned == false)
        #expect(store.tasks.first?.completedAt != nil)
    }

    @Test("corrupt store is moved aside")
    func corruptStoreIsMovedAside() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DesktopPetPlannerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("planner.json")
        try Data("not json".utf8).write(to: fileURL)

        let store = TaskStore(fileURL: fileURL)

        #expect(throws: StoreError.self) {
            try store.load()
        }
        #expect(store.tasks.isEmpty)
        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("planner-corrupt-") }
        #expect(backups.count == 1)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("DesktopPetPlannerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("planner.json")
    }
}
