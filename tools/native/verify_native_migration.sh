#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SMOKE_BINARY="${TMPDIR:-/tmp}/native_migration_smoke"

swiftc -o "$SMOKE_BINARY" \
  "$ROOT_DIR/apple/TodoList/Sources/Models/TodoModels.swift" \
  "$ROOT_DIR/apple/TodoList/Sources/Data/TodoDatabase.swift" \
  "$ROOT_DIR/apple/TodoList/Sources/Stores/TodoStore.swift" \
  "$ROOT_DIR/apple/TodoList/Sources/Support/DataTransferService.swift" \
  "$ROOT_DIR/tools/native/native_migration_smoke.swift" \
  -framework AppKit \
  -framework SwiftUI \
  -lsqlite3

"$SMOKE_BINARY"
