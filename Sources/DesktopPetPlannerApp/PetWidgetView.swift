import AppKit
import PetPlannerCore
import SwiftUI

struct PetWidgetView: View {
    @EnvironmentObject private var viewModel: PlannerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                petIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text("桌面计划")
                        .font(.headline)
                    Text("显示 \(viewModel.pinnedTasks.count) / 今天 \(viewModel.tasks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.pinnedTasks.isEmpty {
                Text("暂无桌面显示事项")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.pinnedTasks) { task in
                        PetTaskLine(task: task)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.18))
        )
        .onTapGesture {
            reopenMainWindow()
        }
    }

    private var petIcon: some View {
        Image("MuPlan-generated-icon", bundle: .module)
            .resizable()
            .scaledToFill()
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private func reopenMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let mainWindow = NSApplication.shared.windows.first { window in
            !(window is NSPanel)
        }
        mainWindow?.level = .floating
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

private struct PetTaskLine: View {
    let task: PlannerTask

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(task.status.localizedTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(task.priority == .urgent ? .red : .secondary)
                if task.priority == .urgent {
                    Text("紧急")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                }
                Spacer(minLength: 4)
                if let displayTime = task.displayTime {
                    Text(displayTime, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(task.title)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension TaskStatus {
    var localizedTitle: String {
        switch self {
        case .active:
            return "进行中"
        case .waiting:
            return "等待中"
        case .later:
            return "稍后"
        case .done:
            return "已完成"
        }
    }
}
