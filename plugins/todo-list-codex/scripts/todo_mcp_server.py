#!/usr/bin/env python3
import json
import os
import sqlite3
import sys
import traceback
import uuid
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path


APP_DB_PATH = Path.home() / "Library" / "Application Support" / "com.todolist.app" / "todo.db"
VALID_STATUSES = {"pending", "completed", "overdue"}
VALID_PRIORITIES = {1, 2, 3, 4}
DEFAULT_TAG_COLORS = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"]


def db_path() -> Path:
    configured = os.environ.get("TODO_LIST_DB_PATH")
    return Path(configured).expanduser() if configured else APP_DB_PATH


def now_timestamp() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def normalize_due_date(value):
    if value in ("", None):
        return None
    text = str(value).strip()
    if not text:
        return None
    if len(text) >= 10:
        candidate = text[:10]
        try:
            datetime.strptime(candidate, "%Y-%m-%d")
            return candidate
        except ValueError:
            pass
    raise ValueError("due_date must be YYYY-MM-DD or an ISO date/time string")


def require_status(value: str) -> str:
    if value not in VALID_STATUSES:
        raise ValueError("status must be one of: pending, completed, overdue")
    return value


def require_priority(value) -> int:
    priority = int(value)
    if priority not in VALID_PRIORITIES:
        raise ValueError("priority must be one of: 1, 2, 3, 4")
    return priority


@contextmanager
def connect():
    path = db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    ensure_schema(conn)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS todos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT,
            screenshot_path TEXT,
            due_date TEXT,
            status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'overdue')),
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            completed_at TEXT
        );

        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            color TEXT DEFAULT '#3B82F6',
            created_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS todo_tags (
            todo_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (todo_id, tag_id),
            FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT DEFAULT (datetime('now'))
        );

        INSERT OR IGNORE INTO settings (key, value) VALUES
            ('shortcut_quick_input', 'F2'),
            ('shortcut_show_list', 'F3'),
            ('appearance_mode', 'system'),
            ('hide_dock_icon', 'false'),
            ('app_language', 'system');

        CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
        CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
        CREATE INDEX IF NOT EXISTS idx_todo_tags_todo ON todo_tags(todo_id);
        CREATE INDEX IF NOT EXISTS idx_todo_tags_tag ON todo_tags(tag_id);
        """
    )
    columns = {row["name"] for row in conn.execute("PRAGMA table_info(todos)")}
    if "priority" not in columns:
        conn.execute("ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 1")


def row_to_todo(row: sqlite3.Row, tags_by_todo: dict[str, list[dict]]) -> dict:
    todo_id = row["id"]
    return {
        "id": todo_id,
        "title": row["title"],
        "content": row["content"],
        "screenshot_path": row["screenshot_path"],
        "due_date": row["due_date"],
        "status": row["status"],
        "priority": row["priority"] if row["priority"] is not None else 1,
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
        "completed_at": row["completed_at"],
        "tags": tags_by_todo.get(todo_id, []),
    }


def fetch_tags_by_todo(conn: sqlite3.Connection, todo_ids: list[str]) -> dict[str, list[dict]]:
    if not todo_ids:
        return {}
    placeholders = ",".join("?" for _ in todo_ids)
    rows = conn.execute(
        f"""
        SELECT tt.todo_id, tg.id, tg.name, tg.color, tg.created_at
        FROM todo_tags tt
        JOIN tags tg ON tg.id = tt.tag_id
        WHERE tt.todo_id IN ({placeholders})
        ORDER BY tg.name COLLATE NOCASE ASC
        """,
        todo_ids,
    ).fetchall()
    grouped: dict[str, list[dict]] = {}
    for row in rows:
        grouped.setdefault(row["todo_id"], []).append(
            {
                "id": row["id"],
                "name": row["name"],
                "color": row["color"],
                "created_at": row["created_at"],
            }
        )
    return grouped


def fetch_todo(conn: sqlite3.Connection, todo_id: str) -> dict:
    row = conn.execute("SELECT * FROM todos WHERE id = ?", (todo_id,)).fetchone()
    if row is None:
        raise ValueError(f"todo not found: {todo_id}")
    return row_to_todo(row, fetch_tags_by_todo(conn, [todo_id]))


def resolve_tag_ids(conn: sqlite3.Connection, args: dict) -> list[str]:
    tag_ids = list(args.get("tag_ids") or [])
    tag_names = [str(name).strip() for name in args.get("tag_names") or [] if str(name).strip()]
    create_missing = bool(args.get("create_missing_tags", True))
    for name in tag_names:
        row = conn.execute("SELECT id FROM tags WHERE name = ?", (name,)).fetchone()
        if row:
            tag_ids.append(row["id"])
            continue
        if not create_missing:
            raise ValueError(f"tag not found: {name}")
        tag_id = str(uuid.uuid4()).upper()
        color = DEFAULT_TAG_COLORS[len(tag_ids) % len(DEFAULT_TAG_COLORS)]
        conn.execute(
            "INSERT INTO tags (id, name, color, created_at) VALUES (?, ?, ?, ?)",
            (tag_id, name, color, now_timestamp()),
        )
        tag_ids.append(tag_id)
    return list(dict.fromkeys(tag_ids))


def replace_todo_tags(conn: sqlite3.Connection, todo_id: str, tag_ids: list[str]) -> None:
    conn.execute("DELETE FROM todo_tags WHERE todo_id = ?", (todo_id,))
    for tag_id in tag_ids:
        if conn.execute("SELECT 1 FROM tags WHERE id = ?", (tag_id,)).fetchone() is None:
            raise ValueError(f"tag not found: {tag_id}")
        conn.execute("INSERT OR IGNORE INTO todo_tags (todo_id, tag_id) VALUES (?, ?)", (todo_id, tag_id))


def tool_database_info(_args: dict) -> dict:
    path = db_path()
    with connect() as conn:
        todo_count = conn.execute("SELECT COUNT(*) AS count FROM todos").fetchone()["count"]
        open_count = conn.execute("SELECT COUNT(*) AS count FROM todos WHERE status != 'completed'").fetchone()["count"]
        tag_count = conn.execute("SELECT COUNT(*) AS count FROM tags").fetchone()["count"]
    return {
        "database_path": str(path),
        "exists": path.exists(),
        "todo_count": todo_count,
        "open_todo_count": open_count,
        "tag_count": tag_count,
    }


def tool_list_todos(args: dict) -> dict:
    status = args.get("status")
    if status is not None:
        require_status(status)
    include_completed = bool(args.get("include_completed", True))
    limit = int(args.get("limit", 50))
    if limit < 1 or limit > 200:
        raise ValueError("limit must be between 1 and 200")
    where = []
    params = []
    if status:
        where.append("status = ?")
        params.append(status)
    elif not include_completed:
        where.append("status != 'completed'")
    if args.get("search"):
        where.append("(title LIKE ? OR content LIKE ?)")
        term = f"%{args['search']}%"
        params.extend([term, term])
    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    with connect() as conn:
        rows = conn.execute(
            f"SELECT * FROM todos {where_sql} ORDER BY updated_at DESC, created_at DESC LIMIT ?",
            [*params, limit],
        ).fetchall()
        todo_ids = [row["id"] for row in rows]
        tags_by_todo = fetch_tags_by_todo(conn, todo_ids)
        todos = [row_to_todo(row, tags_by_todo) for row in rows]
    return {"todos": todos, "count": len(todos)}


def tool_get_todo(args: dict) -> dict:
    with connect() as conn:
        return {"todo": fetch_todo(conn, str(args["id"]))}


def tool_create_todo(args: dict) -> dict:
    title = str(args.get("title", "")).strip()
    if not title:
        raise ValueError("title is required")
    priority = require_priority(args.get("priority", 3))
    status = require_status(args.get("status", "pending"))
    timestamp = now_timestamp()
    todo_id = str(uuid.uuid4()).upper()
    completed_at = timestamp if status == "completed" else None
    with connect() as conn:
        conn.execute(
            """
            INSERT INTO todos (
                id, title, content, screenshot_path, due_date, status,
                created_at, updated_at, completed_at, priority
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                todo_id,
                title,
                args.get("content"),
                args.get("screenshot_path"),
                normalize_due_date(args.get("due_date")),
                status,
                timestamp,
                timestamp,
                completed_at,
                priority,
            ),
        )
        replace_todo_tags(conn, todo_id, resolve_tag_ids(conn, args))
        todo = fetch_todo(conn, todo_id)
    return {"todo": todo}


def tool_update_todo(args: dict) -> dict:
    todo_id = str(args["id"])
    assignments = []
    params = []
    if "title" in args:
        title = str(args["title"]).strip()
        if not title:
            raise ValueError("title cannot be empty")
        assignments.append("title = ?")
        params.append(title)
    for arg_name, column in (("content", "content"), ("screenshot_path", "screenshot_path")):
        if arg_name in args:
            assignments.append(f"{column} = ?")
            params.append(args[arg_name])
    if "due_date" in args:
        assignments.append("due_date = ?")
        params.append(normalize_due_date(args.get("due_date")))
    if "priority" in args:
        assignments.append("priority = ?")
        params.append(require_priority(args["priority"]))
    if "status" in args:
        status = require_status(args["status"])
        assignments.append("status = ?")
        params.append(status)
        assignments.append("completed_at = ?")
        params.append(now_timestamp() if status == "completed" else None)
    should_replace_tags = "tag_ids" in args or "tag_names" in args
    if not assignments and not should_replace_tags:
        raise ValueError("provide at least one field to update")
    assignments.append("updated_at = ?")
    params.append(now_timestamp())
    params.append(todo_id)
    with connect() as conn:
        if conn.execute("SELECT 1 FROM todos WHERE id = ?", (todo_id,)).fetchone() is None:
            raise ValueError(f"todo not found: {todo_id}")
        if assignments:
            conn.execute(f"UPDATE todos SET {', '.join(assignments)} WHERE id = ?", params)
        if should_replace_tags:
            replace_todo_tags(conn, todo_id, resolve_tag_ids(conn, args))
        todo = fetch_todo(conn, todo_id)
    return {"todo": todo}


def tool_delete_todo(args: dict) -> dict:
    todo_id = str(args["id"])
    with connect() as conn:
        cursor = conn.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
        if cursor.rowcount == 0:
            raise ValueError(f"todo not found: {todo_id}")
    return {"deleted": True, "id": todo_id}


def tool_list_tags(_args: dict) -> dict:
    with connect() as conn:
        rows = conn.execute("SELECT id, name, color, created_at FROM tags ORDER BY name COLLATE NOCASE ASC").fetchall()
    return {"tags": [dict(row) for row in rows], "count": len(rows)}


def tool_create_tag(args: dict) -> dict:
    name = str(args.get("name", "")).strip()
    if not name:
        raise ValueError("name is required")
    color = str(args.get("color") or "#3B82F6")
    tag_id = str(uuid.uuid4()).upper()
    with connect() as conn:
        conn.execute(
            "INSERT INTO tags (id, name, color, created_at) VALUES (?, ?, ?, ?)",
            (tag_id, name, color, now_timestamp()),
        )
        row = conn.execute("SELECT id, name, color, created_at FROM tags WHERE id = ?", (tag_id,)).fetchone()
    return {"tag": dict(row)}


TOOLS = {
    "todo_database_info": {
        "description": "Return the Todo List database path and basic counts.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        "handler": tool_database_info,
    },
    "list_todos": {
        "description": "List todos from the local Todo List database.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "status": {"type": "string", "enum": sorted(VALID_STATUSES)},
                "include_completed": {"type": "boolean", "default": True},
                "search": {"type": "string"},
                "limit": {"type": "integer", "minimum": 1, "maximum": 200, "default": 50},
            },
            "additionalProperties": False,
        },
        "handler": tool_list_todos,
    },
    "get_todo": {
        "description": "Get one todo by id.",
        "inputSchema": {
            "type": "object",
            "required": ["id"],
            "properties": {"id": {"type": "string"}},
            "additionalProperties": False,
        },
        "handler": tool_get_todo,
    },
    "create_todo": {
        "description": "Create a todo. Missing tag_names are created by default.",
        "inputSchema": {
            "type": "object",
            "required": ["title"],
            "properties": {
                "title": {"type": "string"},
                "content": {"type": ["string", "null"]},
                "screenshot_path": {"type": ["string", "null"]},
                "due_date": {"type": ["string", "null"], "description": "YYYY-MM-DD or ISO date/time."},
                "status": {"type": "string", "enum": sorted(VALID_STATUSES), "default": "pending"},
                "priority": {"type": "integer", "enum": sorted(VALID_PRIORITIES), "default": 3},
                "tag_ids": {"type": "array", "items": {"type": "string"}},
                "tag_names": {"type": "array", "items": {"type": "string"}},
                "create_missing_tags": {"type": "boolean", "default": True},
            },
            "additionalProperties": False,
        },
        "handler": tool_create_todo,
    },
    "update_todo": {
        "description": "Update todo fields. Passing tag_ids or tag_names replaces the todo tag set.",
        "inputSchema": {
            "type": "object",
            "required": ["id"],
            "properties": {
                "id": {"type": "string"},
                "title": {"type": "string"},
                "content": {"type": ["string", "null"]},
                "screenshot_path": {"type": ["string", "null"]},
                "due_date": {"type": ["string", "null"], "description": "YYYY-MM-DD, ISO date/time, or null to clear."},
                "status": {"type": "string", "enum": sorted(VALID_STATUSES)},
                "priority": {"type": "integer", "enum": sorted(VALID_PRIORITIES)},
                "tag_ids": {"type": "array", "items": {"type": "string"}},
                "tag_names": {"type": "array", "items": {"type": "string"}},
                "create_missing_tags": {"type": "boolean", "default": True},
            },
            "additionalProperties": False,
        },
        "handler": tool_update_todo,
    },
    "delete_todo": {
        "description": "Delete a todo by id.",
        "inputSchema": {
            "type": "object",
            "required": ["id"],
            "properties": {"id": {"type": "string"}},
            "additionalProperties": False,
        },
        "handler": tool_delete_todo,
    },
    "list_tags": {
        "description": "List all tags.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        "handler": tool_list_tags,
    },
    "create_tag": {
        "description": "Create a tag.",
        "inputSchema": {
            "type": "object",
            "required": ["name"],
            "properties": {
                "name": {"type": "string"},
                "color": {"type": "string", "default": "#3B82F6"},
            },
            "additionalProperties": False,
        },
        "handler": tool_create_tag,
    },
}


def write_response(payload: dict) -> None:
    sys.stdout.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
    sys.stdout.flush()


def tool_result(result: dict) -> dict:
    text = json.dumps(result, ensure_ascii=False, indent=2)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": result,
    }


def handle_request(message: dict) -> dict | None:
    method = message.get("method")
    request_id = message.get("id")
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": message.get("params", {}).get("protocolVersion", "2024-11-05"),
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "todo-list-codex", "version": "0.1.0"},
            },
        }
    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "tools": [
                    {
                        "name": name,
                        "description": tool["description"],
                        "inputSchema": tool["inputSchema"],
                    }
                    for name, tool in TOOLS.items()
                ]
            },
        }
    if method == "tools/call":
        params = message.get("params") or {}
        name = params.get("name")
        if name not in TOOLS:
            raise ValueError(f"unknown tool: {name}")
        result = TOOLS[name]["handler"](params.get("arguments") or {})
        return {"jsonrpc": "2.0", "id": request_id, "result": tool_result(result)}
    if request_id is None:
        return None
    raise ValueError(f"unsupported method: {method}")


def main() -> None:
    for line in sys.stdin:
        if not line.strip():
            continue
        try:
            message = json.loads(line)
            response = handle_request(message)
            if response is not None:
                write_response(response)
        except Exception as exc:
            request_id = None
            try:
                request_id = json.loads(line).get("id")
            except Exception:
                pass
            print(traceback.format_exc(), file=sys.stderr)
            write_response(
                {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32000, "message": str(exc)},
                }
            )


if __name__ == "__main__":
    main()
