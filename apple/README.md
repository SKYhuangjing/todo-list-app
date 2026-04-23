# Todo List Native macOS App

`apple/TodoList` is the active application in this repository. It is a pure Swift Package app built with SwiftUI, AppKit interop, SQLite, and Carbon global hotkeys.

## Build and Run

From the repo root:

```bash
./tools/native/setup_local_signing.sh
swift build --package-path apple/TodoList
./tools/native/build_and_run.sh
```

Packaged run helpers:

```bash
./tools/native/build_and_run.sh --verify
./tools/native/build_and_run.sh --logs
./tools/native/build_and_run.sh --telemetry
./tools/native/build_and_run.sh --debug
```

## Package Layout

```text
apple/TodoList/
├── Package.swift
└── Sources/
    ├── App/                   # App entry and scenes
    ├── Data/                  # SQLite schema and persistence
    ├── Models/                # Shared domain models and defaults
    ├── Stores/                # Observable state and settings bootstrap
    ├── Support/               # Router, window registry, shortcuts, screenshot, import/export
    └── Views/                 # Dashboard, sidebar, detail, Quick Add, settings, menu bar
```

## Main Components

- `App/TodoListApp.swift`
  Creates the dashboard window, menu bar extra, and Settings scene.
- `Data/TodoDatabase.swift`
  Owns schema creation, CRUD, settings persistence, and JSON import/export payload compatibility.
- `Stores/TodoStore.swift`
  Loads the shared database snapshot and drives sidebar, list, detail, and tag selection state.
- `Stores/AppSettingsStore.swift`
  Bootstraps appearance, shortcuts, and Dock visibility from SQLite.
- `Support/AppRouter.swift`
  Centralizes dashboard, Quick Add, Settings, and quit actions.
- `Support/GlobalShortcutManager.swift`
  Registers Carbon hotkeys and routes them into the app.
- `Support/ScreenshotService.swift`
  Uses native Screen Capture permission APIs plus `screencapture -i` for interactive capture.
- `Support/DataTransferService.swift`
  Imports and exports JSON backups compatible with the earlier Tauri shape.

## Behavior Notes

- Shared database path:
  `~/Library/Application Support/com.todolist.app/todo.db`
- Screenshot files are stored under:
  `~/Library/Application Support/com.todolist.app/screenshots/`
- Code defaults:
  `F2` for Quick Add, `F3` for Dashboard, `hide_dock_icon=false`
- Local settings are preserved if an existing database already contains older values
- Dock hiding is opt-in from Settings and defaults to off
- `tools/native/setup_local_signing.sh` creates a stable self-signed identity for local development, so Screen Recording permission survives rebuilds even without an Apple Developer account

## Verification

Build and package verification:

```bash
swift build --package-path apple/TodoList
./tools/native/build_and_run.sh --verify
```

Migration smoke verification:

```bash
./tools/native/verify_native_migration.sh
```

Telemetry verification:

```bash
./tools/native/build_and_run.sh --telemetry
```

The telemetry stream is useful for checking:

- shortcut registration
- dashboard / Quick Add routing
- settings window opens

## Icons

App icons are generated from `tauri/src-tauri/icons/design/icon_fullbleed.svg`.

```bash
node tools/assets/generate-icons.mjs
```

`tools/native/build_and_run.sh` copies the generated `tauri/src-tauri/icons/icon.icns` into `dist/native/TodoListApp.app`.
