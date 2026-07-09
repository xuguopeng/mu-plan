# Desktop Pet Planner Design

Date: 2026-07-09

## Goal

Build a simple Mac-native planning app for interrupted work. The app helps the user remember what to return to after switching tasks, especially when they ask AI tools to do work and then move on to something else.

The app should feel light, always visible, and fast to input into. It is not a full project management system. Its main job is to keep the user's active and easy-to-forget tasks visible on the desktop.

## First Version Scope

The first version is a Mac-native desktop app built with Swift and SwiftUI.

It includes:

- A small draggable desktop pet window.
- A visible list of selected pinned tasks beside or inside the pet widget.
- A click-to-open planning panel.
- A global keyboard shortcut for quick task entry.
- Rule-based natural language parsing for times, urgency, and waiting states.
- Manual "waiting finished" flow plus explicit timed reminders.
- Local-only persistence.
- macOS notifications and subtle in-app pet state changes for reminders.

It excludes:

- Cross-device sync.
- Account login.
- Team collaboration.
- Calendar integration.
- Automatic detection that an AI tool has finished.
- Complex project management views.

## Product Shape

The app is not a sidebar or menu bar-first utility. Its primary presence is a small desktop pet-like widget that sits in an unobtrusive screen area and stays visible during daily work.

The widget can be dragged anywhere on the screen. The app remembers its last position.

The widget shows:

- A small pet icon or character.
- A configurable set of visible tasks.
- A compact count such as "shown 4 / today 12".

The user chooses which tasks appear on the desktop. The app can also suggest tasks to show based on urgency, waiting state, and active work state.

## Core User Flow

1. The user starts working on something.
2. They get interrupted or ask an AI tool to do work.
3. They press a global shortcut and type a short note, such as:
   - "20 minutes later remind me to check Cursor errors"
   - "confirm the quote before 2pm, urgent"
   - "wait for AI to finish, then continue editing styles"
4. The app parses useful metadata where possible.
5. The task is saved locally.
6. If the task is important, waiting, or manually pinned, it appears in the desktop pet widget.
7. When reminder time arrives, macOS sends a notification and the pet widget changes subtly.
8. The user clicks the pet widget to open the planning panel, then resumes, completes, pins, unpins, or postpones the task.

## Desktop Pet Widget

The desktop widget is a small, always-available window.

Behavior:

- It is draggable.
- It remembers position across launches.
- It is visually quiet by default.
- It can stay above normal windows when needed.
- Clicking the pet or task area opens the planning panel.
- It shows a configurable number of pinned tasks.

Task display:

- One-line title or note.
- Status label: urgent, waiting, active, later, done.
- Optional time: due time, reminder time, or elapsed waiting time.

The desktop widget should support showing multiple tasks because the user's daily work volume is manageable and they want the important visible set to stay in sight.

## Planning Panel

The planning panel opens when the user clicks the desktop pet widget.

It provides:

- Today's full task list.
- Quick input field.
- Pinned task selection.
- Task actions: complete, pin, unpin, wait, postpone, delete.
- Simple filters for all, pinned, waiting, urgent, done.

The panel should feel like an operational surface, not a landing page. It should prioritize dense, readable information and fast actions.

## Quick Input

The app registers `Option + Space` as the default global keyboard shortcut. If the shortcut conflicts with another app, the user can change it in settings.

When triggered:

- A small one-line input window appears.
- The user types a task and presses Return.
- The app parses the text, saves the task, and closes the input.
- Escape closes the input without saving.

The quick input is the main creation path. Opening the full panel should not be required for normal use.

## Natural Language Parsing

The first version uses rule-based parsing, not AI.

It should recognize:

- Relative reminders: "20 minutes later", "in 30 minutes", "after 1 hour".
- Absolute times: "2pm", "14:00", "before 2pm".
- Day words: "today", "tomorrow".
- Urgency keywords: "urgent", "important", "before".
- Waiting keywords: "wait for AI", "wait for Cursor", "wait for Claude", "AI finishes".

If text indicates a waiting task but no time is parsed, the app marks it as waiting and pinned without assigning a reminder time.

Parsing failures should not block entry. The raw task text is still saved.

## Reminder Model

The first version uses reliable reminder behavior instead of trying to detect whether an AI task has actually finished.

Reminder types:

- Time-based reminders from parsed or default times.
- Manual waiting completion, where the user marks that a waiting task is ready to resume.

When a reminder fires:

- The app sends a macOS notification.
- The pet widget changes subtly: highlight, badge, or one gentle attention animation.
- The task remains visible until completed, postponed, or unpinned.

The app should avoid aggressive interruption.

## Data Model

Task:

- `id`: stable unique identifier.
- `title`: user-entered text or cleaned display title.
- `rawText`: original input text.
- `status`: active, waiting, later, done.
- `priority`: normal or urgent.
- `isPinned`: whether shown in desktop widget.
- `createdAt`: creation date.
- `updatedAt`: last update date.
- `dueAt`: optional due time.
- `remindAt`: optional reminder time.
- `completedAt`: optional completion time.
- `source`: quick input, panel, or future import.

Settings:

- Desktop widget position.
- Number of pinned tasks to show.
- Default waiting reminder duration.
- Global shortcut.
- Whether the widget floats above normal windows.

## Architecture

Use Swift and SwiftUI for the first version.

Main components:

- `TaskStore`: owns task persistence and task mutations.
- `TaskParser`: parses quick input text into task fields.
- `ReminderScheduler`: schedules and cancels macOS notifications.
- `PetWindowController`: owns the desktop pet window behavior.
- `QuickInputWindowController`: owns global shortcut input.
- `PlanningPanelView`: main task management panel.
- `SettingsStore`: persists user preferences.

The app uses JSON persistence in the first version because the data is small, local, and easy to debug. SwiftData can be introduced later if query complexity grows.

## Error Handling

If notification permission is missing, the app should still save tasks and show in-widget reminders, while asking the user to enable notifications.

If shortcut registration fails because of a conflict, the app should show a clear setting to choose another shortcut.

If parsing fails, the task should still be saved as plain text.

If local data cannot be loaded, the app should preserve the unreadable file if possible and start with an empty task list rather than crashing.

## Testing

First version testing should focus on:

- Rule-based parsing for relative time, absolute time, urgency, and waiting keywords.
- Reminder scheduling and cancellation.
- Pinning and unpinning tasks.
- Completing and postponing tasks.
- Desktop widget position persistence.
- App restart state restoration.
- Quick input save and cancel behavior.

Manual QA should verify:

- The pet widget is visible but not annoying.
- The widget can be dragged and remembers position.
- Notifications appear at the expected time.
- The panel remains usable with a realistic day's worth of tasks.

## First Version Defaults

These defaults keep implementation focused while still allowing future customization:

- Pet visual style: a simple neutral character icon with subtle state changes.
- Default global shortcut: `Option + Space`.
- Default visible pinned task count: 4.
- Full-screen behavior: the widget does not float above macOS full-screen apps in the first version.

The product requirement is clear without these decisions: a Mac-native, draggable desktop pet planner that keeps selected interrupted-work tasks visible and supports fast keyboard entry.
