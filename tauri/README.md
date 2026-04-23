# Legacy Tauri App

`tauri/` contains the earlier Tauri + React implementation plus the Rust bridge experiments that predate the native macOS app.

This directory is now legacy scope. Keep it for:

- behavior comparison during migration follow-up
- JSON backup compatibility checks
- icon asset generation inputs
- old Tauri-specific experiments

## Layout

```text
tauri/
├── package.json              # Legacy web/Tauri package entry
├── src/                      # React UI
├── src-tauri/                # Tauri Rust app, bundle config, icons
├── rust-core/                # Earlier Rust bridge / UniFFI experiments
├── public/                   # Static web assets
└── vite/tailwind/ts config   # Legacy frontend toolchain config
```

## Run Legacy App

From the repo root:

```bash
cd tauri
npm install
npm run tauri dev
```

Build:

```bash
cd tauri
npm run tauri build
```

## Notes

- The active shipping path is `../apple/TodoList`.
- Shared icon scripts still live at the repo root under `../tools/assets/`.
- Native packaging scripts read icon assets from `tauri/src-tauri/icons/`.
