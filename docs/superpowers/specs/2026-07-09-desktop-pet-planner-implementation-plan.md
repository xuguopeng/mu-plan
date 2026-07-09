# Desktop Pet Planner Implementation Plan

Date: 2026-07-09

Source design: `docs/superpowers/specs/2026-07-09-desktop-pet-planner-design.md`

## Build Strategy

Build the Mac app in thin vertical slices. Each slice should compile and keep the app usable. Start with persistence and core task behavior, then add quick input and reminders, then add the desktop pet window and final interaction polish.

## Phase 1: Mac App Skeleton

Goal: create a runnable SwiftUI macOS app with predictable structure.

Tasks:

- Create an Xcode macOS SwiftUI app project.
- Set app name and bundle structure.
- Add a basic app entry point.
- Add placeholder views for:
  - desktop pet widget,
  - planning panel,
  - quick input window.
- Add unit test target.
- Confirm the app builds and launches.

Acceptance:

- `xcodebuild` can build the app.
- Launching the app shows a basic planning panel or placeholder window.

## Phase 2: Core Data Model and JSON Persistence

Goal: support local task and settings storage before UI complexity.

Tasks:

- Define `PlannerTask`, `TaskStatus`, `TaskPriority`, and `TaskSource`.
- Define `PlannerSettings`.
- Implement `TaskStore`.
- Implement JSON load/save in Application Support.
- Preserve corrupt unreadable data by moving it aside before starting fresh.
- Add mutations:
  - create,
  - update,
  - complete,
  - delete,
  - pin,
  - unpin,
  - postpone,
  - mark waiting,
  - mark active.
- Add unit tests for persistence and task mutations.

Acceptance:

- Tasks survive app restart.
- Settings survive app restart.
- Store tests pass.

## Phase 3: Rule-Based Quick Input Parser

Goal: turn fast natural-language input into useful task metadata.

Tasks:

- Implement `TaskParser`.
- Parse relative reminders:
  - "20 minutes later",
  - "in 30 minutes",
  - "after 1 hour",
  - "20分钟后",
  - "半小时后",
  - "一小时后".
- Parse absolute times:
  - "2pm",
  - "14:00",
  - "before 2pm",
  - "下午2点",
  - "14点",
  - "2点前".
- Parse day words:
  - today,
  - tomorrow,
  - 今天,
  - 明天.
- Parse urgency:
  - urgent,
  - important,
  - before,
  - 紧急,
  - 重要,
  - 截止,
  - 前.
- Parse waiting state:
  - AI,
  - Cursor,
  - Claude,
  - wait/waiting/finish language,
  - 等 AI,
  - 等 Cursor,
  - 等 Claude,
  - 跑完,
  - 结束.
- Apply default 20-minute reminder for waiting tasks with no parsed time.
- Save raw text even when parsing finds no metadata.
- Add unit tests for representative English and Chinese phrases.

Acceptance:

- Parser tests cover time, urgency, waiting, and fallback behavior.
- Unrecognized input still creates a normal task.

## Phase 4: Reminder Scheduling

Goal: make reminders reliable without depending on AI completion detection.

Tasks:

- Implement `ReminderScheduler` using `UserNotifications`.
- Request notification permission on first relevant use.
- Schedule notification when a task has `remindAt`.
- Cancel notification when task is completed or deleted.
- Reschedule notification when task is postponed or reminder time changes.
- Add in-app reminder state so the pet widget can highlight reminded tasks.
- Add testable scheduling abstraction around `UNUserNotificationCenter`.

Acceptance:

- Creating a task with a reminder schedules one notification.
- Completing or deleting the task cancels the notification.
- App remains usable when notification permission is denied.

## Phase 5: Quick Input Window and Global Shortcut

Goal: make task capture fast enough to use while working.

Tasks:

- Register default global shortcut `Option + Space`.
- Add a settings path for changing the shortcut if registration fails.
- Implement `QuickInputWindowController`.
- Show a compact one-line input window.
- Return saves parsed task and closes the window.
- Escape closes without saving.
- After save, update the desktop pet widget immediately.

Acceptance:

- `Option + Space` opens quick input from another app.
- Return creates a task.
- Escape cancels.
- Shortcut conflict has a visible recovery path.

## Phase 6: Desktop Pet Window

Goal: create the always-visible, draggable task anchor.

Tasks:

- Implement `PetWindowController` with an `NSPanel` or borderless `NSWindow`.
- Embed SwiftUI pet widget content.
- Make the window draggable.
- Persist and restore window position.
- Keep it visually quiet and compact.
- Show default 4 pinned tasks.
- Show count such as "shown 4 / today 12".
- Click pet or task area to open planning panel.
- Do not float above macOS full-screen apps in version 1.

Acceptance:

- Pet widget can be moved and remembers position after relaunch.
- Pinned tasks appear in the widget.
- Clicking opens the panel.
- The widget does not dominate the desktop.

## Phase 7: Planning Panel UI

Goal: provide complete daily task management without turning into a heavy project manager.

Tasks:

- Build `PlanningPanelView`.
- Show today's full task list.
- Add compact quick input field.
- Add filters:
  - all,
  - pinned,
  - waiting,
  - urgent,
  - done.
- Add actions:
  - complete,
  - pin,
  - unpin,
  - wait,
  - postpone,
  - delete.
- Add pinned task selection.
- Keep layout dense, readable, and operational.

Acceptance:

- User can manage a realistic day of tasks from the panel.
- Pinning changes the desktop widget immediately.
- Completing and postponing update reminders correctly.

## Phase 8: Pet Visual States

Goal: make reminders visible without being annoying.

Tasks:

- Add neutral idle pet state.
- Add waiting state.
- Add urgent/reminded highlight state.
- Add one gentle attention animation when a reminder fires.
- Avoid continuous distracting animation.

Acceptance:

- Reminder state is obvious at a glance.
- Idle state is calm enough to leave on screen all day.

## Phase 9: Settings

Goal: expose only settings needed for first-version control.

Tasks:

- Add default visible pinned task count setting.
- Add default waiting reminder duration setting.
- Add global shortcut setting.
- Add float-above-normal-windows setting.
- Persist settings with `SettingsStore`.

Acceptance:

- Settings persist after relaunch.
- Changing settings updates behavior without restarting where practical.

## Phase 10: QA and Packaging

Goal: verify the app behaves well as a daily desktop utility.

Tasks:

- Run unit tests.
- Run build in Debug and Release.
- Manually test:
  - app launch,
  - quick input,
  - task parsing,
  - reminders,
  - notification denied path,
  - pet dragging,
  - relaunch state restore,
  - pinned task updates,
  - panel actions.
- Fix usability issues found during manual testing.
- Document how to build and run locally.

Acceptance:

- App builds cleanly.
- Tests pass.
- Manual QA checklist passes.
- README explains local build and run steps.

## Suggested Implementation Order

1. Phase 1: skeleton.
2. Phase 2: model and persistence.
3. Phase 3: parser.
4. Phase 7: planning panel basic UI.
5. Phase 6: desktop pet window.
6. Phase 5: quick input and shortcut.
7. Phase 4: reminders.
8. Phase 8: pet states.
9. Phase 9: settings.
10. Phase 10: QA and packaging.

The order intentionally builds a useful task manager before deep window behavior. That keeps the app testable while native desktop features are added.

## First Implementation Milestone

The first milestone should stop after phases 1 through 3 plus a minimal planning panel:

- App launches.
- User can create tasks in the panel.
- Tasks persist.
- Parser extracts urgency, waiting, and reminder times.
- Unit tests cover store and parser.

After this milestone, the next slice can safely add the pet window and quick input.
