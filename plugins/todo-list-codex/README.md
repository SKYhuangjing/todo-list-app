# Todo List Codex Plugin

This repo-local Codex plugin exposes the Todo List app SQLite database through MCP.

Default database:

```text
~/Library/Application Support/com.todolist.app/todo.db
```

Set `TODO_LIST_DB_PATH` in `.mcp.json` to point Codex at a test database.

Available MCP tools:

- `todo_database_info`
- `list_todos`
- `get_todo`
- `create_todo`
- `update_todo`
- `delete_todo`
- `list_tags`
- `create_tag`

The server creates the same core tables as the app when the database does not exist.
