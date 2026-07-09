import AppKit
import PetPlannerCore
import SwiftUI

@main
struct DesktopPetPlannerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = PlannerViewModel()

    var body: some Scene {
        WindowGroup("MuPlan") {
            PlanningPanelView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        bringWindowsToFront()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        bringWindowsToFront()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func bringWindowsToFront() {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.level = .floating
                window.collectionBehavior.insert(.canJoinAllSpaces)
                window.makeKeyAndOrderFront(nil)
            }
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
