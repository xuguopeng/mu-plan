import Foundation

public struct PlannerSettings: Codable, Equatable, Sendable {
    public var visiblePinnedTaskCount: Int
    public var defaultWaitingReminderMinutes: Int
    public var globalShortcut: String
    public var floatsAboveNormalWindows: Bool
    public var petWindowOriginX: Double
    public var petWindowOriginY: Double

    public init(
        visiblePinnedTaskCount: Int = 4,
        defaultWaitingReminderMinutes: Int = 20,
        globalShortcut: String = "Option+Space",
        floatsAboveNormalWindows: Bool = true,
        petWindowOriginX: Double = 80,
        petWindowOriginY: Double = 80
    ) {
        self.visiblePinnedTaskCount = visiblePinnedTaskCount
        self.defaultWaitingReminderMinutes = defaultWaitingReminderMinutes
        self.globalShortcut = globalShortcut
        self.floatsAboveNormalWindows = floatsAboveNormalWindows
        self.petWindowOriginX = petWindowOriginX
        self.petWindowOriginY = petWindowOriginY
    }
}
