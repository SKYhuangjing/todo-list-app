# Native Migration Progress - 2026-04-20

## Scope
- Objective: migrate the legacy Tauri + React app capability surface from `tauri/` into the native macOS SwiftUI app under `apple/TodoList`.
- Status: native migration delivered and runtime smoke-verified on 2026-04-21.

## Implemented
- Shared SQLite data bridge to `/Users/sky/Library/Application Support/com.todolist.app/todo.db`
- Main dashboard reading/writing the real database
- Native tag loading and sidebar tag filter
- Native task create / complete / reopen / delete
- Native settings surface for:
  - appearance mode
  - global shortcuts
  - tag management
  - import/export
- Native menu bar window actions
- Native quick add utility window implementation
- Screenshot capture service wiring
- Global shortcut registration infrastructure
- Native app icon packaging into the built `.app`
- Dock visibility setting with default `off`
- Migration smoke verifier at `tools/native/verify_native_migration.sh`

## Verified
- `swift build --package-path apple/TodoList` passes
- `./tools/native/build_and_run.sh --verify` passes
- `./tools/native/verify_native_migration.sh` passes
- Native app launches from the packaged `.app` bundle and registers global shortcuts in telemetry
- Quick Add draft persistence is smoke-verified against SQLite, including selected tags and screenshot path
- Import/export JSON round-trip is smoke-verified against the native database layer
- Screenshot permission detection now uses native macOS Screen Capture APIs instead of the old `screencapture /dev/null` approximation
- Menu bar copy and permission copy now match the native app naming (`Todo List`)

## Remaining Notes
- Existing local settings are preserved. If a machine already stored `shortcut_quick_input=F4` from an earlier native preview build, the app keeps that value until the user changes it in Settings.
- Shortcut registration is verified in runtime telemetry; shell-synthesized key events were not a reliable proof path for Carbon hotkey delivery in this CLI environment, so the smoke verifier focuses on the persisted shortcut configuration and routed window actions in app code.
