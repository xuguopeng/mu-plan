import PetPlannerCore
import SwiftUI

@main
struct DesktopPetPlannerApp: App {
    @StateObject private var viewModel = PlannerViewModel()

    var body: some Scene {
        WindowGroup("Desktop Pet Planner") {
            PlanningPanelView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}
