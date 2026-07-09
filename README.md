# Desktop Pet Planner

A Mac-native SwiftUI planner for interrupted work. The first milestone includes a minimal planning panel, local JSON persistence, and rule-based parsing for quick task input.

## Current Milestone

Implemented:

- Swift Package macOS app scaffold.
- Core task model and settings model.
- JSON persistence in Application Support.
- Store operations for create, complete, delete, pin, unpin, waiting, active, and postpone.
- Rule-based parser for English and Chinese task input.
- Minimal SwiftUI planning panel with input, filters, pinned tasks, and task actions.
- Unit tests for parser and store behavior.

Not implemented yet:

- Desktop pet floating window.
- Global shortcut quick input.
- macOS notifications.
- Pet visual reminder states.

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Run

```bash
swift run DesktopPetPlanner
```

Data is saved to:

```text
~/Library/Application Support/DesktopPetPlanner/planner.json
```
