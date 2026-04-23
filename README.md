# Todo List

Native macOS TODO app built with SwiftUI and AppKit interop.

The repository still contains the earlier Tauri + React implementation under `tauri/`, but the active product and verification path now live under `apple/TodoList`.

## Current Status

- Primary app: native macOS SwiftUI package at `apple/TodoList`
- Migration status: delivered and smoke-verified
- Legacy code: Tauri + React kept for reference, JSON compatibility, and asset tooling

## What Works

- Dashboard window with sidebar, task list, and detail pane
- Menu bar extra with quick access to today work
- Quick Add utility window
- Global shortcuts for Quick Add and Dashboard
- SQLite-backed tasks, tags, settings, and screenshot paths
- Tag filtering and tag management
- JSON import/export compatible with the earlier Tauri backup shape
- Screenshot capture with native macOS Screen Recording permission checks
- Dock visibility toggle in Settings
- Packaged app icon generation and bundle packaging

## Quick Start

### Requirements

- macOS 15+
- Xcode Command Line Tools
- Swift 5.9+

Node.js is only needed for legacy Tauri work and icon generation.

### Build Native App

```bash
swift build --package-path apple/TodoList
```

### One-Time Local Signing Setup

Without an Apple Developer account, use the repo's self-signed local identity so macOS treats rebuilt apps as the same code identity for TCC permissions like Screen Recording.

```bash
./tools/native/setup_local_signing.sh
```

### Run Packaged Native App

```bash
./tools/native/build_and_run.sh
```

Useful modes:

```bash
./tools/native/build_and_run.sh --verify
./tools/native/build_and_run.sh --logs
./tools/native/build_and_run.sh --telemetry
./tools/native/build_and_run.sh --debug
```

### Smoke Verify Migration-Critical Flows

```bash
./tools/native/verify_native_migration.sh
```

That smoke verifier covers:

- default settings bootstrap
- Quick Add persistence
- tag relation persistence
- screenshot path persistence
- JSON import/export round-trip

## Runtime Notes

- Shared database: `~/Library/Application Support/com.todolist.app/todo.db`
- Screenshot directory: `~/Library/Application Support/com.todolist.app/screenshots/`
- Default shortcuts in code: `F2` for Quick Add, `F3` for Dashboard
- Existing local settings are preserved, so older preview builds may keep user-local values until changed in Settings

## Repo Layout

```text
todo-list-app/
├── apple/TodoList/            # Active native macOS app (SwiftUI + AppKit interop)
├── doc/                       # Architecture and migration docs
├── dist/native/               # Native packaged app output
├── tools/native/              # Native build/run/verify tools
├── tools/assets/              # Shared icon generation tools
└── tauri/                     # Legacy Tauri + React app and Rust bridge experiments
```

## Documents

- [Current design](doc/DESIGN.md)
- [Native migration progress](doc/native-migration-progress-2026-04-20.md)
- [Native app notes](apple/README.md)
- [Legacy Tauri notes](tauri/README.md)

## Legacy Scope

The web/Tauri implementation is no longer the primary shipping path. Keep it only when you need one of these:

- compare behavior during migration follow-up
- preserve JSON import/export compatibility
- regenerate shared assets such as icons

If you are making product changes, start from `apple/TodoList` unless the task is explicitly about legacy code under `tauri/`.
