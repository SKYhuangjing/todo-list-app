import { useEffect, useState } from "react";
import { invoke, convertFileSrc } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { getCurrentWindow } from "@tauri-apps/api/window";
import Database from "@tauri-apps/plugin-sql";
import { save, open } from "@tauri-apps/plugin-dialog";
import { writeTextFile, readTextFile } from "@tauri-apps/plugin-fs";
import {
  Plus,
  Settings,
  Check,
  Circle,
  Trash2,
  Tag as TagIcon,
  Calendar,
  Camera,
  X,
  ArrowLeft,
  Sparkles,
  Download,
  Upload,
  Keyboard,
  Search,
  Inbox,
  Palette,
  Moon,
  Sun,
  Hash,
  CheckCircle2,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import "./App.css";

// ============ 类型定义 ============
interface Tag {
  id: string;
  name: string;
  color: string;
  created_at: string;
}

interface Todo {
  id: string;
  title: string;
  content: string | null;
  screenshot_path: string | null;
  due_date: string | null;
  status: string;
  created_at: string;
  updated_at: string;
  completed_at: string | null;
  priority: number;
}

interface TodoWithTags extends Todo {
  tags: Tag[];
}

type FilterType = "all" | "today" | "upcoming" | "completed";
type ViewType = "list" | "settings" | "input";

// ============ 数据库单例 ============
let db: Database | null = null;

async function getDb(): Promise<Database> {
  if (!db) {
    db = await Database.load("sqlite:todo.db");
  }
  return db;
}

// ============ 主应用 ============
function App() {
  const [todos, setTodos] = useState<TodoWithTags[]>([]);
  const [tags, setTags] = useState<Tag[]>([]);
  const [filter, setFilter] = useState<FilterType>("all");
  const [selectedTagId, setSelectedTagId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [focusedId, setFocusedId] = useState<string | null>(null);
  const [toast, setToast] = useState<{message: string, type: 'success' | 'info'} | null>(null);
  const [view, setView] = useState<ViewType>("list");
  const [isQuickInput, setIsQuickInput] = useState(false);
  const [loading, setLoading] = useState(true);
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const [shortcuts, setShortcuts] = useState({ quick_input: "F2", show_list: "F3" });

  // 监听托盘菜单事件
  useEffect(() => {
    const unlisten = listen("open-settings", () => {
      setView("settings");
      getCurrentWindow().show();
      getCurrentWindow().setFocus();
    });
    
    return () => {
      unlisten.then(f => f());
    };
  }, []);

  // 初始化主题
  useEffect(() => {
    const savedTheme = localStorage.getItem("theme") as "light" | "dark" | null;
    const initialTheme = savedTheme || "light";
    setTheme(initialTheme);
    document.documentElement.setAttribute("data-theme", initialTheme);
  }, []);

  const handleThemeChange = (newTheme: "light" | "dark") => {
    setTheme(newTheme);
    localStorage.setItem("theme", newTheme);
    document.documentElement.setAttribute("data-theme", newTheme);
  };

  useEffect(() => {
    initApp();
  }, []);

  useEffect(() => {
    if (!isQuickInput) {
      loadTodos();
    }
  }, [filter, isQuickInput, selectedTagId, searchQuery]);

  // 主窗口获得焦点时刷新数据（快速输入保存后）
  useEffect(() => {
    if (isQuickInput) return;
    
    const handleFocus = () => {
      loadTodos();
      loadTags();
    };
    
    window.addEventListener("focus", handleFocus);
    return () => window.removeEventListener("focus", handleFocus);
  }, [isQuickInput, filter]);

  const initApp = async () => {
    try {
      const label = await getCurrentWindow().label;
      setIsQuickInput(label === "quick-input");
      if (label !== "quick-input") {
        await loadTodos();
        await loadTags();
      }
      await syncShortcuts();
    } catch (err) {
      console.error("初始化失败:", err);
    }
    setLoading(false);
  };

  const showToast = (message: string, type: 'success' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const syncShortcuts = async () => {
    try {
      const database = await getDb();
      const settings: { key: string; value: string }[] = await database.select(
        "SELECT key, value FROM settings WHERE key IN ('shortcut_quick_input', 'shortcut_show_list')"
      );
      
      const config = { quick_input: "F2", show_list: "F3" };
      settings.forEach((s) => {
        if (s.key === "shortcut_quick_input") config.quick_input = s.value;
        if (s.key === "shortcut_show_list") config.show_list = s.value;
      });
      setShortcuts(config);
      // 同步给 Rust 后端
      await invoke("update_shortcuts", { config });
    } catch (err) {
      console.error("同步快捷键失败:", err);
    }
  };

  const loadTodos = async () => {
    try {
      const database = await getDb();
      const today = await invoke<string>("get_today_date");
      
      let sql = "";
      const params: any[] = [];
      
      switch (filter) {
        case "all":
          sql = "SELECT * FROM todos WHERE status = 'pending' ORDER BY created_at DESC";
          break;
        case "today":
          sql = `SELECT * FROM todos WHERE (date(due_date) <= '${today}' OR due_date IS NULL) AND status = 'pending' ORDER BY created_at DESC`;
          break;
        case "upcoming":
          sql = `SELECT * FROM todos WHERE date(due_date) > '${today}' AND status = 'pending' ORDER BY due_date ASC`;
          break;
        case "completed":
          sql = "SELECT * FROM todos WHERE status = 'completed' ORDER BY completed_at DESC";
          break;
      }

      // 如果有标签过滤
      if (selectedTagId) {
        // 由于标签是多对多关系，我们需要修改 SQL 或者在 JS 中过滤
        // 这里简单的在 SQL 中通过子查询过滤
        sql = `SELECT * FROM todos WHERE id IN (SELECT todo_id FROM todo_tags WHERE tag_id = $1) AND (${sql.split('FROM todos WHERE ')[1]})`;
        params.push(selectedTagId);
      }

      // 搜索过滤
      if (searchQuery.trim()) {
        const searchSql = "(title LIKE $SEARCH OR content LIKE $SEARCH)";
        const searchIdx = params.length + 1;
        params.push(`%${searchQuery}%`);
        
        if (sql.includes("WHERE")) {
          sql = sql.replace("WHERE", `WHERE ${searchSql.replace(/\$SEARCH/g, `$${searchIdx}`)} AND `);
        } else {
          sql += ` WHERE ${searchSql.replace(/\$SEARCH/g, `$${searchIdx}`)}`;
        }
      }
      
      const todoList: Todo[] = await database.select(sql, params);
      
      // 获取每个 TODO 的标签
      const todosWithTags: TodoWithTags[] = await Promise.all(
        todoList.map(async (todo) => {
          const todoTags: Tag[] = await database.select(
            `SELECT t.* FROM tags t 
             JOIN todo_tags tt ON t.id = tt.tag_id 
             WHERE tt.todo_id = $1`,
            [todo.id]
          );
          return { ...todo, tags: todoTags };
        })
      );
      
      setTodos(todosWithTags);
    } catch (err) {
      console.error("加载 TODO 失败:", err);
    }
  };

  const loadTags = async () => {
    try {
      const database = await getDb();
      const tagList: Tag[] = await database.select("SELECT * FROM tags ORDER BY name");
      setTags(tagList);
    } catch (err) {
      console.error("加载标签失败:", err);
    }
  };

  const toggleComplete = async (id: string, currentStatus: string) => {
    try {
      const database = await getDb();
      const timestamp = await invoke<string>("get_current_timestamp");
      
      const newStatus = currentStatus === "pending" ? "completed" : "pending";
      await database.execute(
        "UPDATE todos SET status = $1, completed_at = $2, updated_at = $3 WHERE id = $4",
         [newStatus, newStatus === "completed" ? timestamp : null, timestamp, id]
      );
      showToast(newStatus === "completed" ? "任务已完成" : "任务已重置");
      await loadTodos();
    } catch (err) {
      console.error("切换状态失败:", err);
    }
  };

  const deleteTodo = async (id: string) => {
    try {
      const database = await getDb();
      await database.execute("DELETE FROM todos WHERE id = $1", [id]);
      showToast("任务已删除", 'info');
      await loadTodos();
    } catch (err) {
      console.error("删除失败:", err);
    }
  };

  // 键盘导航
  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      // 如果正在输入，不处理
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        if (e.key === "Escape") {
          (e.target as HTMLElement).blur();
        }
        return;
      }

      switch (e.key) {
        case "j":
          e.preventDefault();
          setFocusedId(prev => {
            const idx = todos.findIndex(t => t.id === prev);
            if (idx === -1) return todos[0]?.id || null;
            return todos[Math.min(idx + 1, todos.length - 1)].id;
          });
          break;
        case "k":
          e.preventDefault();
          setFocusedId(prev => {
            const idx = todos.findIndex(t => t.id === prev);
            if (idx === -1) return todos[todos.length - 1]?.id || null;
            return todos[Math.max(idx - 1, 0)].id;
          });
          break;
        case "/":
          e.preventDefault();
          const searchInput = document.querySelector('input[placeholder="搜索..."]') as HTMLInputElement;
          searchInput?.focus();
          break;
        case "Enter":
          if (focusedId) {
            const todo = todos.find(t => t.id === focusedId);
            if (todo) toggleComplete(todo.id, todo.status);
          }
          break;
      }
    };

    window.addEventListener("keydown", handleGlobalKeyDown);
    return () => window.removeEventListener("keydown", handleGlobalKeyDown);
  }, [todos, focusedId]);

  if (loading) {
    return <div className="loading">加载中...</div>;
  }

  // 快捷输入窗口
  if (isQuickInput) {
    return <QuickInputView onSave={loadTodos} />;
  }

  // 内联输入视图
  if (view === "input") {
    return <InlineInputView onSave={() => { loadTodos(); setView("list"); }} onBack={() => setView("list")} />;
  }

  // 设置页面
  if (view === "settings") {
    return (
      <SettingsView
        tags={tags}
        onBack={() => setView("list")}
        onTagsChange={loadTags}
        theme={theme}
        onThemeChange={handleThemeChange}
        shortcuts={shortcuts}
        onShortcutsChange={syncShortcuts}
      />
    );
  }

  // 主窗口 - 1Password 三栏生产力架构
  const detailedTodo = todos.find(t => t.id === focusedId);

  return (
    <main className="app-container" data-tauri-drag-region>
      {/* 第一栏：侧边导航 */}
      <aside className="w-[200px] border-r bg-sidebar flex flex-col p-4" data-tauri-drag-region>
        <div className="flex-1 overflow-y-auto">
          <div className="mb-6">
            <h2 className="mb-2 px-2 text-xs font-semibold tracking-tight text-muted-foreground">
              视图
            </h2>
            <div className="space-y-1">
              <Button
                variant={filter === "all" && !selectedTagId ? "secondary" : "ghost"}
                className="w-full justify-start"
                onClick={() => { setFilter("all"); setSelectedTagId(null); }}
              >
                <Inbox className="mr-2 h-4 w-4 text-blue-500" />
                所有任务
              </Button>
              <Button
                variant={filter === "today" ? "secondary" : "ghost"}
                className="w-full justify-start"
                onClick={() => { setFilter("today"); setSelectedTagId(null); }}
              >
                <Calendar className="mr-2 h-4 w-4 text-orange-500" />
                今日
              </Button>
              <Button
                variant={filter === "upcoming" ? "secondary" : "ghost"}
                className="w-full justify-start"
                onClick={() => { setFilter("upcoming"); setSelectedTagId(null); }}
              >
                <Calendar className="mr-2 h-4 w-4 text-purple-500" />
                未来
              </Button>
              <Button
                variant={filter === "completed" ? "secondary" : "ghost"}
                className="w-full justify-start"
                onClick={() => { setFilter("completed"); setSelectedTagId(null); }}
              >
                <CheckCircle2 className="mr-2 h-4 w-4 text-green-500" />
                已完成
              </Button>
            </div>
          </div>
          
          <div>
            <h2 className="mb-2 px-2 text-xs font-semibold tracking-tight text-muted-foreground mt-6">
              标签
            </h2>
            <div className="space-y-1">
              {tags.map((tag) => (
                <Button
                  key={tag.id}
                  variant={selectedTagId === tag.id ? "secondary" : "ghost"}
                  className="w-full justify-start"
                  onClick={() => { setSelectedTagId(tag.id); setFilter("all"); }}
                >
                  <Hash className="mr-2 h-4 w-4 text-muted-foreground" />
                  {tag.name}
                </Button>
              ))}
            </div>
          </div>
        </div>

        <div className="mt-auto pt-4">
          <Button variant="ghost" className="w-full justify-start text-muted-foreground" onClick={() => setView("settings")}>
            <Settings className="mr-2 h-4 w-4" />
            设置
          </Button>
        </div>
      </aside>

      {/* 第二栏：任务列表摘要 */}
      <section className="w-[320px] flex flex-col border-r bg-background" data-tauri-drag-region>
        <header className="p-4 flex flex-col gap-4 border-b" data-tauri-drag-region>
          <div className="flex items-center justify-between">
            <h1 className="text-lg font-bold tracking-tight">
              {filter === "all" && !selectedTagId && "所有任务"}
              {filter === "today" && "今日"}
              {filter === "upcoming" && "未来"}
              {filter === "completed" && "已完成"}
              {selectedTagId && tags.find(t => t.id === selectedTagId)?.name}
            </h1>
            <Button variant="ghost" size="icon" className="h-8 w-8 text-blue-500" onClick={async () => {
              const { WebviewWindow } = await import("@tauri-apps/api/webviewWindow");
              const quickInput = await WebviewWindow.getByLabel("quick-input");
              if (quickInput) {
                await quickInput.show();
                await quickInput.setFocus();
              }
            }}>
              <Plus className="h-5 w-5" />
            </Button>
          </div>

          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input 
              type="text" 
              placeholder="搜索..." 
              className="pl-9 h-9 bg-muted/50 border-none"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </header>

        <ul className="flex-1 overflow-y-auto">
          {todos.length === 0 ? (
            <div className="p-10 text-center text-sm text-muted-foreground">
              无任务
            </div>
          ) : (
            todos.map((todo) => (
              <li 
                key={todo.id} 
                className={`flex items-start gap-3 p-4 border-b cursor-pointer transition-colors ${focusedId === todo.id ? "bg-accent" : "hover:bg-muted/50"}`}
                onClick={() => setFocusedId(todo.id)}
              >
                <button
                  className="mt-0.5 text-muted-foreground hover:text-foreground transition-colors"
                  onClick={(e) => { e.stopPropagation(); toggleComplete(todo.id, todo.status); }}
                >
                  {todo.status === "completed" ? 
                    <CheckCircle2 className="h-5 w-5 text-green-500" /> : 
                    <Circle className="h-5 w-5" />
                  }
                </button>
                <div className="flex-1 space-y-1 overflow-hidden">
                  <h3 className={`text-sm font-medium leading-none truncate ${todo.status === "completed" ? "line-through text-muted-foreground" : ""}`}>
                    {todo.title}
                  </h3>
                  <p className="text-xs text-muted-foreground truncate">{todo.due_date || "无截止日期"}</p>
                </div>
              </li>
            ))
          )}
        </ul>

        <footer className="p-3 border-t text-xs text-center text-muted-foreground">
          {todos.length} 个任务
        </footer>
      </section>

      {/* 第三栏：详细信息面板 */}
      <article className="flex-1 bg-background overflow-y-auto p-12">
        {detailedTodo ? (
          <div className="max-w-3xl mx-auto space-y-8">
            <header className="space-y-4" data-tauri-drag-region>
              <div className="flex items-center gap-2">
                <Badge variant={detailedTodo.priority === 1 ? "destructive" : detailedTodo.priority === 2 ? "default" : "secondary"}>
                  优先级 {detailedTodo.priority}
                </Badge>
                {detailedTodo.status === "completed" && (
                  <Badge variant="outline" className="text-green-500 border-green-500">
                    已完成
                  </Badge>
                )}
              </div>
              <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
                {detailedTodo.title}
              </h1>
            </header>

            <section className="space-y-6">
              {detailedTodo.content && (
                <div className="space-y-2">
                  <h4 className="text-sm font-semibold tracking-tight text-muted-foreground uppercase">描述</h4>
                  <p className="text-base text-foreground leading-relaxed whitespace-pre-wrap">
                    {detailedTodo.content}
                  </p>
                </div>
              )}

              {detailedTodo.screenshot_path && (
                <div className="space-y-2">
                  <h4 className="text-sm font-semibold tracking-tight text-muted-foreground uppercase">相关截图</h4>
                  <div className="mt-2 rounded-lg overflow-hidden border shadow-sm">
                    <img 
                      src={convertFileSrc(detailedTodo.screenshot_path)} 
                      alt="截图" 
                      className="w-full block object-cover"
                    />
                  </div>
                </div>
              )}

              <div className="space-y-4">
                <h4 className="text-sm font-semibold tracking-tight text-muted-foreground uppercase">信息</h4>
                <div className="flex flex-col gap-3">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">创建于</span>
                    <span className="font-medium">{detailedTodo.created_at}</span>
                  </div>
                  {detailedTodo.due_date && (
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">截止日期</span>
                      <span className="font-medium">{detailedTodo.due_date}</span>
                    </div>
                  )}
                  <div className="flex flex-wrap gap-2 pt-2">
                    {detailedTodo.tags.map(tag => (
                      <Badge key={tag.id} variant="outline" style={{ borderColor: tag.color, color: tag.color }}>
                        {tag.name}
                      </Badge>
                    ))}
                  </div>
                </div>
              </div>
            </section>

            <footer className="mt-12 pt-6 border-t flex gap-3">
              <Button 
                variant="destructive" 
                className="w-full sm:w-auto"
                onClick={() => deleteTodo(detailedTodo.id)}
              >
                <Trash2 className="mr-2 h-4 w-4" />
                删除任务
              </Button>
            </footer>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center h-full text-muted-foreground opacity-50">
            <Inbox className="h-16 w-16 mb-4" />
            <p className="text-base font-medium">选择一个任务以查看详情</p>
          </div>
        )}
      </article>

      {toast && (
        <div className={`fixed bottom-4 right-4 flex items-center gap-2 px-4 py-3 rounded-md shadow-lg text-sm font-medium z-50 ${toast.type === 'success' ? 'bg-green-600 text-white' : 'bg-destructive text-destructive-foreground'}`}>
          {toast.type === 'success' ? <Check className="h-4 w-4" /> : <Trash2 className="h-4 w-4" />}
          <span>{toast.message}</span>
        </div>
      )}
    </main>
  );
}

// ============ 快捷输入组件 ============
function QuickInputView({ onSave }: { onSave: () => void }) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [priority, setPriority] = useState(4);
  const [tags, setTags] = useState<Tag[]>([]);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [showTagInput, setShowTagInput] = useState(false);
  const [showDescription, setShowDescription] = useState(false);
  const [newTagName, setNewTagName] = useState("");
  const [screenshotPath, setScreenshotPath] = useState<string | null>(null);
  const [isCapturing, setIsCapturing] = useState(false);
  const [hasPermission, setHasPermission] = useState(true);

  // NLP 解析日期
  useEffect(() => {
    const parseNLP = async () => {
      const today = new Date();
      let targetDate: Date | null = null;
      
      const lowerTitle = title.toLowerCase();
      
      if (lowerTitle.includes("今天")) {
        targetDate = today;
      } else if (lowerTitle.includes("明天")) {
        const tomorrow = new Date();
        tomorrow.setDate(today.getDate() + 1);
        targetDate = tomorrow;
      } else if (lowerTitle.includes("后天")) {
        const afterTomorrow = new Date();
        afterTomorrow.setDate(today.getDate() + 2);
        targetDate = afterTomorrow;
      }
      
      // 匹配 "周几"
      const dayMap: { [key: string]: number } = { "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "日": 0, "天": 0 };
      const match = lowerTitle.match(/周([一二三四五六日天])/);
      if (match) {
        const targetDay = dayMap[match[1]];
        const currentDay = today.getDay();
        let diff = targetDay - currentDay;
        if (diff <= 0) diff += 7;
        
        const nextDay = new Date();
        nextDay.setDate(today.getDate() + diff);
        targetDate = nextDay;
      }

      if (targetDate) {
        const formattedDate = targetDate.toISOString().split('T')[0];
        setDueDate(formattedDate);
      }
    };
    
    if (title.length > 1) {
      parseNLP();
    }
  }, [title]);

  // 同步主题设置
  useEffect(() => {
    const savedTheme = localStorage.getItem("theme") || "light";
    document.documentElement.setAttribute("data-theme", savedTheme);
  }, []);

  useEffect(() => {
    loadTags();
    
    // 窗口获得焦点时重新加载标签（同步设置页面的变更）
    const handleFocus = () => {
      loadTags();
    };
    window.addEventListener("focus", handleFocus);
    return () => window.removeEventListener("focus", handleFocus);
  }, []);

  const loadTags = async () => {
    try {
      const database = await getDb();
      const tagList: Tag[] = await database.select("SELECT * FROM tags ORDER BY name");
      setTags(tagList);
    } catch (err) {
      console.error("加载标签失败:", err);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    try {
      const database = await getDb();
      const id = await invoke<string>("generate_uuid");
      const timestamp = await invoke<string>("get_current_timestamp");
      
      await database.execute(
        `INSERT INTO todos (id, title, content, screenshot_path, due_date, priority, status, created_at, updated_at) 
         VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7, $7)`,
        [id, title, content || null, screenshotPath, dueDate || null, priority, timestamp]
      );
      
      // 关联标签
      for (const tagId of selectedTags) {
        await database.execute(
          "INSERT INTO todo_tags (todo_id, tag_id) VALUES ($1, $2)",
          [id, tagId]
        );
      }
      
      setTitle("");
      setContent("");
      setDueDate("");
      setSelectedTags([]);
      setScreenshotPath(null);
      onSave();
      
      // 关闭窗口
      const window = getCurrentWindow();
      await window.hide();
    } catch (err) {
      console.error("创建失败:", err);
    }
  };

  const handleCreateTag = async () => {
    if (!newTagName.trim()) return;
    try {
      const database = await getDb();
      const id = await invoke<string>("generate_uuid");
      const timestamp = await invoke<string>("get_current_timestamp");
      const colors = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"];
      const color = colors[Math.floor(Math.random() * colors.length)];
      
      await database.execute(
        "INSERT INTO tags (id, name, color, created_at) VALUES ($1, $2, $3, $4)",
        [id, newTagName, color, timestamp]
      );
      
      setNewTagName("");
      setShowTagInput(false);
      await loadTags();
    } catch (err) {
      console.error("创建标签失败:", err);
    }
  };

  const toggleTag = (tagId: string) => {
    setSelectedTags((prev) =>
      prev.includes(tagId) ? prev.filter((id) => id !== tagId) : [...prev, tagId]
    );
  };

  // 检查截图权限
  useEffect(() => {
    const checkPermission = async () => {
      const permitted = await invoke<boolean>("check_screenshot_permission");
      setHasPermission(permitted);
    };
    checkPermission();
    // 每次窗口显示时也可以检查一下
    const unlisten = getCurrentWindow().onFocusChanged(({ payload: focused }) => {
      if (focused) checkPermission();
    });
    return () => {
      unlisten.then(u => u());
    };
  }, []);

  const handleRequestPermission = async () => {
    await invoke("request_screenshot_permission");
  };

  const handleCaptureScreenshot = async () => {
    setIsCapturing(true);
    try {
      // 先隐藏窗口
      const currentWindow = getCurrentWindow();
      await currentWindow.hide();
      // 等待一小段时间让窗口完全隐藏
      await new Promise(resolve => setTimeout(resolve, 200));
      // 调用截图命令
      const path = await invoke<string>("capture_screenshot");
      setScreenshotPath(path);
      // 重新显示窗口
      await currentWindow.show();
      await currentWindow.setFocus();
    } catch (err) {
      console.error("截图失败:", err);
      // 确保窗口重新显示
      const currentWindow = getCurrentWindow();
      await currentWindow.show();
      await currentWindow.setFocus();
    }
    setIsCapturing(false);
  };

  const handleRemoveScreenshot = () => {
    setScreenshotPath(null);
  };

  // 监听主题变化
  useEffect(() => {
    const applyTheme = () => {
      const savedTheme = localStorage.getItem("theme") || "light";
      document.documentElement.setAttribute("data-theme", savedTheme);
    };
    
    applyTheme();
    
    // 监听 storage 事件（当其他窗口改变 localStorage 时触发）
    window.addEventListener("storage", applyTheme);
    
    // 每次窗口获得焦点时也检查主题
    window.addEventListener("focus", applyTheme);
    
    return () => {
      window.removeEventListener("storage", applyTheme);
      window.removeEventListener("focus", applyTheme);
    };
  }, []);



  const handleClose = async () => {
    try {
      const currentWindow = getCurrentWindow();
      await currentWindow.hide();
    } catch (err) {
      console.error("关闭窗口失败:", err);
    }
  };

  useEffect(() => {
    const handleKeyDown = async (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        await handleClose();
      }
    };
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, []);

  return (
    <main className="flex flex-col h-screen p-6 bg-background overflow-hidden" data-tauri-drag-region>
      <header className="flex items-center justify-between mb-6" data-tauri-drag-region>
        <div className="flex items-center gap-2 text-muted-foreground">
          <Sparkles className="h-4 w-4" />
          <span className="text-sm font-semibold tracking-tight">Quick Add</span>
        </div>
        <Button variant="ghost" size="icon" onClick={handleClose} className="h-6 w-6">
          <X className="h-4 w-4" />
        </Button>
      </header>
      
      <form onSubmit={handleSubmit} className="flex-1 flex flex-col gap-5 overflow-y-auto pr-2">
        <Input
          type="text"
          placeholder="捕捉此刻的想法..."
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey && title.trim()) {
              e.preventDefault();
              handleSubmit(e as unknown as React.FormEvent);
            }
          }}
          autoFocus
          className="text-2xl font-bold border-none shadow-none px-0 outline-none focus-visible:ring-0 bg-transparent placeholder:text-muted"
        />

        <div className="flex gap-2">
          {[1, 2, 3, 4].map(p => (
            <Badge
              key={p}
              variant={priority === p ? (p === 1 ? "destructive" : p === 2 ? "default" : "secondary") : "outline"}
              className="cursor-pointer"
              onClick={() => setPriority(p)}
            >
              P{p}
            </Badge>
          ))}
        </div>
        
        {showDescription ? (
          <textarea
            placeholder="添加详细描述..."
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full text-sm bg-transparent border-none resize-none focus:outline-none placeholder:text-muted-foreground"
            rows={3}
            autoFocus
          />
        ) : (
          <Button
            variant="ghost"
            className="w-fit text-muted-foreground justify-start px-0 hover:bg-transparent hover:text-foreground"
            onClick={() => setShowDescription(true)}
          >
            + 添加描述
          </Button>
        )}
        
        {showTagInput && (
          <div className="flex items-center gap-2 mt-2">
            <Input
              type="text"
              placeholder="新标签名称"
              value={newTagName}
              onChange={(e) => setNewTagName(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleCreateTag()}
              className="w-32 h-8 text-xs"
            />
            <Button type="button" size="sm" onClick={handleCreateTag} className="h-8">
              添加
            </Button>
          </div>
        )}
        
        {screenshotPath && (
          <div className="w-48 rounded-md overflow-hidden border">
            <img src={convertFileSrc(screenshotPath)} alt="截图" className="w-full h-auto object-cover" />
          </div>
        )}
        
        <div className="flex flex-col gap-4 mt-auto pt-4 pb-2">
          <div className="flex flex-wrap items-center gap-2">
            <TagIcon className="h-4 w-4 text-muted-foreground" />
            {tags.map((tag) => (
              <Badge
                key={tag.id}
                variant={selectedTags.includes(tag.id) ? "default" : "outline"}
                className="cursor-pointer"
                style={selectedTags.includes(tag.id) ? { backgroundColor: tag.color } : { borderColor: tag.color, color: tag.color }}
                onClick={() => toggleTag(tag.id)}
              >
                {tag.name}
              </Badge>
            ))}
            <Button
              variant="outline"
              size="sm"
              className="h-6 w-6 p-0 rounded-full"
              onClick={() => setShowTagInput(!showTagInput)}
            >
              +
            </Button>
          </div>
          
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-muted-foreground" />
            <Input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="w-fit h-8 text-xs"
            />
          </div>
          
          <div className="flex items-center justify-between mt-2">
            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={hasPermission ? handleCaptureScreenshot : handleRequestPermission}
                disabled={isCapturing}
              >
                <Camera className="mr-2 h-4 w-4" /> 
                {!hasPermission ? "授权截图" : screenshotPath ? "已截图" : "截图"}
              </Button>
              {screenshotPath && (
                <Button variant="ghost" size="icon" onClick={handleRemoveScreenshot} className="h-8 w-8 text-destructive">
                  <X className="h-4 w-4" />
                </Button>
              )}
            </div>
            
            <Button type="submit" disabled={!title.trim()} className="px-8">
              保存
            </Button>
          </div>
        </div>
      </form>
      
      <p className="text-center text-xs text-muted-foreground mt-4">按 Esc 关闭</p>
    </main>
  );
}

// ============ 内联输入组件 ============
function InlineInputView({ onSave, onBack }: { onSave: () => void; onBack: () => void }) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [priority, setPriority] = useState(4);
  const [tags, setTags] = useState<Tag[]>([]);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [showTagInput, setShowTagInput] = useState(false);
  const [newTagName, setNewTagName] = useState("");

  useEffect(() => {
    loadTags();
  }, []);

  const loadTags = async () => {
    try {
      const database = await getDb();
      const tagList: Tag[] = await database.select("SELECT * FROM tags ORDER BY name");
      setTags(tagList);
    } catch (err) {
      console.error("加载标签失败:", err);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    try {
      const database = await getDb();
      const id = await invoke<string>("generate_uuid");
      const timestamp = await invoke<string>("get_current_timestamp");
      
      await database.execute(
        `INSERT INTO todos (id, title, content, due_date, priority, status, created_at, updated_at) 
         VALUES ($1, $2, $3, $4, $5, 'pending', $6, $6)`,
        [id, title, content || null, dueDate || null, priority, timestamp]
      );
      
      for (const tagId of selectedTags) {
        await database.execute(
          "INSERT INTO todo_tags (todo_id, tag_id) VALUES ($1, $2)",
          [id, tagId]
        );
      }
      
      onSave();
    } catch (err) {
      console.error("创建失败:", err);
    }
  };

  const handleCreateTag = async () => {
    if (!newTagName.trim()) return;
    try {
      const database = await getDb();
      const id = await invoke<string>("generate_uuid");
      const timestamp = await invoke<string>("get_current_timestamp");
      const colors = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"];
      const color = colors[Math.floor(Math.random() * colors.length)];
      
      await database.execute(
        "INSERT INTO tags (id, name, color, created_at) VALUES ($1, $2, $3, $4)",
        [id, newTagName, color, timestamp]
      );
      
      setNewTagName("");
      setShowTagInput(false);
      await loadTags();
    } catch (err) {
      console.error("创建标签失败:", err);
    }
  };

  const toggleTag = (tagId: string) => {
    setSelectedTags((prev) =>
      prev.includes(tagId) ? prev.filter((id) => id !== tagId) : [...prev, tagId]
    );
  };

  return (
    <main className="flex flex-col h-full bg-background" data-tauri-drag-region>
      <header className="flex items-center gap-4 p-6 border-b" data-tauri-drag-region>
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="flex items-center gap-2 text-xl font-bold tracking-tight">
          <Sparkles className="h-5 w-5 text-blue-500" /> 新建 TODO
        </h1>
      </header>

      <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-8 max-w-2xl mx-auto w-full">
        <div className="space-y-4">
          <Input
            type="text"
            placeholder="输入任务标题..."
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            autoFocus
            className="text-3xl font-bold border-none shadow-none px-0 outline-none focus-visible:ring-0 bg-transparent placeholder:text-muted"
          />

          <div className="flex gap-2">
            {[1, 2, 3, 4].map(p => (
              <Badge
                key={p}
                variant={priority === p ? (p === 1 ? "destructive" : p === 2 ? "default" : "secondary") : "outline"}
                className="cursor-pointer"
                onClick={() => setPriority(p)}
              >
                P{p}
              </Badge>
            ))}
          </div>
          
          <textarea
            placeholder="详细描述（可选）"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full text-base bg-transparent border-none resize-none focus:outline-none placeholder:text-muted-foreground min-h-[100px]"
          />
        </div>
        
        <div className="space-y-4">
          <label className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase">
            <TagIcon className="h-4 w-4" /> 标签
          </label>
          <div className="flex flex-wrap items-center gap-2">
            {tags.map((tag) => (
              <Badge
                key={tag.id}
                variant={selectedTags.includes(tag.id) ? "default" : "outline"}
                className="cursor-pointer"
                style={selectedTags.includes(tag.id) ? { backgroundColor: tag.color } : { borderColor: tag.color, color: tag.color }}
                onClick={() => toggleTag(tag.id)}
              >
                {tag.name}
              </Badge>
            ))}
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="h-6 w-6 p-0 rounded-full"
              onClick={() => setShowTagInput(!showTagInput)}
            >
              +
            </Button>
          </div>
          {showTagInput && (
            <div className="flex items-center gap-2 mt-2">
              <Input
                type="text"
                placeholder="新标签名称"
                value={newTagName}
                onChange={(e) => setNewTagName(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleCreateTag()}
                className="w-32 h-8 text-xs"
              />
              <Button type="button" size="sm" onClick={handleCreateTag} className="h-8">
                添加
              </Button>
            </div>
          )}
        </div>
        
        <div className="space-y-4">
          <label className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase">
            <Calendar className="h-4 w-4" /> 截止日期
          </label>
          <Input
            type="date"
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            className="w-fit"
          />
        </div>
        
        <div className="flex justify-end gap-3 pt-6 border-t">
          <Button type="button" variant="outline" onClick={onBack}>
            取消
          </Button>
          <Button type="submit" disabled={!title.trim()}>
            保存
          </Button>
        </div>
      </form>
    </main>
  );
}

function SettingsView({
  tags,
  onBack,
  onTagsChange,
  theme,
  onThemeChange,
  shortcuts,
  onShortcutsChange,
}: {
  tags: Tag[];
  onBack: () => void;
  onTagsChange: () => void;
  theme: "light" | "dark";
  onThemeChange: (theme: "light" | "dark") => void;
  shortcuts: { quick_input: string; show_list: string };
  onShortcutsChange: () => void;
}) {
  const [recordingShortcut, setRecordingShortcut] = useState<"quick_input" | "show_list" | null>(null);
  const [newTagName, setNewTagName] = useState("");
  const [importing, setImporting] = useState(false);
  const [exporting, setExporting] = useState(false);

  const updateShortcut = async (key: "quick_input" | "show_list", value: string) => {
    try {
      const database = await getDb();
      await database.execute(
        "UPDATE settings SET value = $1 WHERE key = $2",
        [value, `shortcut_${key}`]
      );
      // 调用父组件的同步方法
      onShortcutsChange();
      setRecordingShortcut(null);
    } catch (err) {
      alert(`保存快捷键失败: ${err}`);
    }
  };

  useEffect(() => {
    if (!recordingShortcut) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      e.preventDefault();
      e.stopPropagation();

      // 忽略单纯的修饰键
      if (["Control", "Shift", "Alt", "Meta"].includes(e.key)) return;

      let key = e.key.toUpperCase();
      if (key === " ") key = "SPACE";
      
      const modifiers = [];
      if (e.ctrlKey) modifiers.push("Ctrl");
      if (e.altKey) modifiers.push("Alt");
      if (e.shiftKey) modifiers.push("Shift");
      if (e.metaKey) modifiers.push("Command");

      const shortcut = modifiers.length > 0 ? `${modifiers.join("+")}+${key}` : key;
      updateShortcut(recordingShortcut, shortcut);
    };

    window.addEventListener("keydown", handleKeyDown, true);
    return () => window.removeEventListener("keydown", handleKeyDown, true);
  }, [recordingShortcut]);

  const createTag = async () => {
    if (!newTagName.trim()) return;
    try {
      const database = await getDb();
      const id = await invoke<string>("generate_uuid");
      const timestamp = await invoke<string>("get_current_timestamp");
      const colors = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"];
      const color = colors[Math.floor(Math.random() * colors.length)];
      
      await database.execute(
        "INSERT INTO tags (id, name, color, created_at) VALUES ($1, $2, $3, $4)",
        [id, newTagName, color, timestamp]
      );
      
      setNewTagName("");
      onTagsChange();
    } catch (err) {
      console.error("创建标签失败:", err);
    }
  };

  const deleteTag = async (id: string) => {
    try {
      const database = await getDb();
      await database.execute("DELETE FROM tags WHERE id = $1", [id]);
      onTagsChange();
    } catch (err) {
      console.error("删除标签失败:", err);
    }
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const database = await getDb();
      const todos: Todo[] = await database.select("SELECT * FROM todos");
      const allTags: Tag[] = await database.select("SELECT * FROM tags");
      
      const todoExports = await Promise.all(
        todos.map(async (todo) => {
          const todoTags: { name: string }[] = await database.select(
            "SELECT t.name FROM tags t JOIN todo_tags tt ON t.id = tt.tag_id WHERE tt.todo_id = $1",
            [todo.id]
          );
          return {
            title: todo.title,
            content: todo.content,
            due_date: todo.due_date,
            status: todo.status,
            tags: todoTags.map((t) => t.name),
            created_at: todo.created_at,
            completed_at: todo.completed_at,
          };
        })
      );
      
      const data = {
        version: "1.0",
        exported_at: new Date().toISOString(),
        todos: todoExports,
        tags: allTags.map((t) => ({ name: t.name, color: t.color })),
      };
      
      const json = JSON.stringify(data, null, 2);
      const path = await save({
        filters: [{ name: "JSON", extensions: ["json"] }],
        defaultPath: `todo-backup-${new Date().toISOString().split("T")[0]}.json`,
      });
      
      if (path) {
        await writeTextFile(path, json);
        alert("导出成功！");
      }
    } catch (err) {
      alert(`导出失败: ${err}`);
    }
    setExporting(false);
  };

  const handleImport = async () => {
    setImporting(true);
    try {
      const path = await open({
        filters: [{ name: "JSON", extensions: ["json"] }],
        multiple: false,
      });
      
      if (path) {
        const content = await readTextFile(path as string);
        const data = JSON.parse(content);
        const database = await getDb();
        
        let importedTags = 0;
        let importedTodos = 0;
        const timestamp = await invoke<string>("get_current_timestamp");
        
        // 导入标签
        for (const tag of data.tags || []) {
          const id = await invoke<string>("generate_uuid");
          try {
            await database.execute(
              "INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES ($1, $2, $3, $4)",
              [id, tag.name, tag.color, timestamp]
            );
            importedTags++;
          } catch {}
        }
        
        // 导入 TODO
        for (const todo of data.todos || []) {
          const id = await invoke<string>("generate_uuid");
          try {
            await database.execute(
              `INSERT INTO todos (id, title, content, due_date, status, created_at, updated_at, completed_at) 
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
              [id, todo.title, todo.content, todo.due_date, todo.status, todo.created_at, timestamp, todo.completed_at]
            );
            importedTodos++;
            
            // 关联标签
            for (const tagName of todo.tags || []) {
              const tagResults: { id: string }[] = await database.select(
                "SELECT id FROM tags WHERE name = $1",
                [tagName]
              );
              if (tagResults.length > 0) {
                await database.execute(
                  "INSERT OR IGNORE INTO todo_tags (todo_id, tag_id) VALUES ($1, $2)",
                  [id, tagResults[0].id]
                );
              }
            }
          } catch {}
        }
        
        alert(`导入成功！导入了 ${importedTodos} 个 TODO 和 ${importedTags} 个标签`);
        onTagsChange();
      }
    } catch (err) {
      alert(`导入失败: ${err}`);
    }
    setImporting(false);
  };

  return (
    <main className="flex flex-col h-full bg-background" data-tauri-drag-region>
      <header className="flex items-center gap-4 p-6 border-b" data-tauri-drag-region>
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <h1 className="text-xl font-bold tracking-tight">设置</h1>
      </header>

      <div className="flex-1 overflow-y-auto p-6 space-y-8 max-w-2xl mx-auto w-full">
        <section className="space-y-4">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-tight">
            <Keyboard className="h-4 w-4" /> 快捷键
          </h2>
          <div className="space-y-2">
            <div className="flex items-center justify-between p-3 rounded-md border bg-card">
              <span className="text-sm font-medium">快捷输入（新建 TODO）</span>
              <Button
                variant={recordingShortcut === "quick_input" ? "destructive" : "outline"}
                size="sm"
                onClick={() => setRecordingShortcut("quick_input")}
              >
                {recordingShortcut === "quick_input" ? "请按键..." : shortcuts.quick_input}
              </Button>
            </div>
            <div className="flex items-center justify-between p-3 rounded-md border bg-card">
              <span className="text-sm font-medium">显示列表</span>
              <Button
                variant={recordingShortcut === "show_list" ? "destructive" : "outline"}
                size="sm"
                onClick={() => setRecordingShortcut("show_list")}
              >
                {recordingShortcut === "show_list" ? "请按键..." : shortcuts.show_list}
              </Button>
            </div>
            <p className="text-xs text-muted-foreground pt-1">点击上方进行修改，修改后立即生效并保存</p>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-tight">
            <Palette className="h-4 w-4" /> 外观
          </h2>
          <div className="flex items-center justify-between p-3 rounded-md border bg-card">
            <span className="flex items-center gap-2 text-sm font-medium">
              {theme === "dark" ? <Moon className="h-4 w-4" /> : <Sun className="h-4 w-4" />} 深色模式
            </span>
            <Button
              variant="outline"
              size="icon"
              className="rounded-full w-10 h-5 shrink-0 relative p-0 overflow-hidden"
              onClick={() => onThemeChange(theme === "dark" ? "light" : "dark")}
            >
              <div className={`absolute top-[2px] w-4 h-4 rounded-full transition-all bg-foreground ${theme === "dark" ? 'translate-x-[18px]' : 'translate-x-[2px]'}`} />
            </Button>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-tight">
            <TagIcon className="h-4 w-4" /> 标签管理
          </h2>
          <div className="flex flex-wrap gap-2">
            {tags.map((tag) => (
              <Badge key={tag.id} variant="outline" className="flex items-center gap-1 pl-2 pr-1 py-1 shadow-sm" style={{ borderColor: tag.color, color: tag.color }}>
                {tag.name}
                <Button variant="ghost" size="icon" className="h-4 w-4 ml-1 hover:bg-transparent hover:text-destructive shrink-0" onClick={() => deleteTag(tag.id)}>
                  <X className="h-3 w-3" />
                </Button>
              </Badge>
            ))}
          </div>
          <div className="flex items-center gap-2 mt-2">
            <Input
              type="text"
              placeholder="新标签名称"
              value={newTagName}
              onChange={(e) => setNewTagName(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && createTag()}
              className="w-48 bg-muted/50"
            />
            <Button onClick={createTag}>添加标签</Button>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-muted-foreground uppercase tracking-tight">
            <Download className="h-4 w-4" /> 数据管理
          </h2>
          <div className="flex gap-3">
            <Button variant="outline" onClick={handleExport} disabled={exporting}>
              <Upload className="mr-2 h-4 w-4" /> {exporting ? "导出中..." : "导出数据"}
            </Button>
            <Button variant="outline" onClick={handleImport} disabled={importing}>
              <Download className="mr-2 h-4 w-4" /> {importing ? "导入中..." : "导入数据"}
            </Button>
          </div>
          <p className="text-xs text-muted-foreground">导出的 JSON 文件可用于备份或迁移</p>
        </section>
      </div>
    </main>
  );
}

export default App;
