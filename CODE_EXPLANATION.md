# Task Manager App – Complete Code Explanation

This document explains how the Flutter Task Management app works end-to-end: **architecture**, **SQLite persistence**, **Riverpod state management**, and **UI/UX behavior** (search/filter, blocked tasks, drafts, loading delays).

---

## Architecture overview (what goes where)

Your `lib/` is structured by responsibility:

- **`constants/`**
  - `enums.dart`: strongly-typed enums for task status + filter options.
- **`core/`**
  - `theme/`: app-wide `ThemeData`.
  - `utils/`: small reusable utilities (debounce, date helpers).
- **`models/`**
  - `task_model.dart`: the domain/data model used across DB + UI.
- **`database/`**
  - `db_helper.dart`: opens/creates the SQLite database.
  - `task_dao.dart`: data-access methods (CRUD) for tasks.
- **`providers/`**
  - `task_provider.dart`: Riverpod providers + controller (single source of truth).
- **`screens/`**
  - `task_list_screen.dart`: list/search/filter + blocked UI + delete.
  - `task_form_screen.dart`: create/edit + dependency selection + draft restore.
- **`widgets/`**
  - `task_card.dart`: polished card UI + status chip + blocked visuals + highlight.
  - `search_bar.dart`: search input field widget.
  - `status_filter.dart`: dropdown widget for status filtering.
- **`main.dart`**
  - app entrypoint; sets theme, Riverpod scope, and home screen.

This is “clean architecture” in a pragmatic Flutter sense: **UI** doesn’t talk to SQLite directly; it talks to **Riverpod**, which talks to a **DAO**, which talks to **SQLite**.

---

## Data model (`TaskModel`)

File: `lib/models/task_model.dart`

### Fields (matches your spec)

- **`id`**: `int?`  
  - `null` before insert, becomes auto-increment primary key after insert.
- **`title`**: `String`
- **`description`**: `String`
- **`dueDate`**: `String` in **ISO format** `yyyy-MM-dd`
- **`status`**: `String` stored as one of: `"To-Do"`, `"In Progress"`, `"Done"`
- **`blockedBy`**: `int?`
  - `null` means “not blocked by another task”
  - otherwise contains the `id` of the task that blocks this one

### DB mapping

`TaskModel.toDb()` returns a map matching the SQLite columns:

- `due_date` is the DB column name (snake_case)
- `blocked_by` is the DB column name

`TaskModel.fromDb()` converts DB rows to `TaskModel`.

---

## SQLite Database

### Database creation (`DbHelper`)

File: `lib/database/db_helper.dart`

Responsibilities:

- Determine database file path using `path_provider`:
  - `getApplicationDocumentsDirectory()`
  - join with `task_manager.db`
- Open the database with `openDatabase(...)`
- Enable foreign keys:
  - `PRAGMA foreign_keys = ON`
- Create the `tasks` table on first run with exactly your schema.

### DAO (CRUD) (`TaskDao`)

File: `lib/database/task_dao.dart`

Responsibilities:

- **Insert**: `insert(TaskModel task)`
  - inserts all fields except `id` (auto increment)
- **Fetch**: `fetchAll()`
  - reads tasks sorted by `id DESC` (newest first)
- **Update**: `update(TaskModel task)`
  - updates row by id
- **Delete**: `deleteById(int id)`
  - runs in a transaction:
    1. sets `blocked_by = NULL` for all tasks that reference the deleted task
    2. deletes the task row

This implements your requirement:
> When deleting a task: remove its reference from other tasks' `blockedBy`.

---

## Provider state management (single source of truth)

File: `lib/providers/task_provider.dart`

### The controller

This app uses the classic `provider` package with a `ChangeNotifier`:

- **`TaskController extends ChangeNotifier`**
  - holds all state + exposes methods to mutate it.
  - created at app start via `ChangeNotifierProvider`.

State fields:
- `List<TaskModel> tasks`
- `bool isLoading`
- `bool isMutating` (create/update in progress)
- `String? error`
- `TaskFilter filter`
- `String query`

Derived getters:
- `filteredTasks`: applies search + filter
- `blockedByMap`: `id -> TaskModel` lookup for dependency logic

### TaskController methods

`TaskController` loads from SQLite on construction:

- **`refresh()`**
  - reloads tasks from DB.
- **`refresh()`**
  - forces reload from DB.
- **`createTask(TaskModel task)`**
  - sets `isMutating = true`
  - waits **2 seconds** (required simulation)
  - inserts in DB
  - reloads tasks
- **`updateTask(TaskModel task)`**
  - sets `isMutating = true`
  - waits **2 seconds**
  - updates DB
  - reloads tasks
- **`deleteTask(int id)`**
  - deletes immediately (no forced 2 seconds)
  - reloads tasks

Why create/update simulate delay but delete does not:
- Your requirement explicitly asked delay for create + update.

---

## Dependency / “Blocked task” logic (Track B)

Implemented in the list UI, using the spec:

If:
- `Task B.blockedBy == Task A.id`
- and `Task A.status != "Done"`

Then:
- Task B is considered **blocked**
- UI disables interactions on B
- UI displays “Blocked by …”

Where this happens:
- `TaskListScreen` reads `blockedByMapProvider` (id → task map)
- for each task `t`, it finds the blocker task:
  - `blocker = blockedByMap[t.blockedBy]`
- blocked if:
  - `t.blockedBy != null`
  - blocker exists
  - blocker.status is not `"Done"`

Blocked UI styling:
- handled in `TaskCard`:
  - grey background
  - reduced opacity
  - tap disabled
  - lock icon shown

---

## Task List Screen (`TaskListScreen`)

File: `lib/screens/task_list_screen.dart`

Main responsibilities:

- Show top controls:
  - **Search bar**
  - **Status filter dropdown**
- Show body:
  - loading state (`CircularProgressIndicator`)
  - error state message
  - empty state UI (“No tasks yet” / “No matching tasks”)
  - list of `TaskCard`
- Provide actions:
  - **FAB** navigates to `TaskFormScreen` (create)
  - **tap card** navigates to `TaskFormScreen(task: t)` (edit) unless blocked
  - **delete** with confirmation dialog + snackbar

### Search behavior (debounced, 300ms)

- `TaskSearchBar` calls `onChanged(value)` on each keystroke.
- Screen uses a `Debouncer(delay: 300ms)` to avoid filtering on every keypress.
- After 300ms idle, it writes to:
  - `taskSearchQueryProvider`
- The list UI watches:
  - `filteredTasksProvider` which re-computes based on query/filter.

### Highlight matching text in titles (stretch goal)

Implemented in `TaskCard`:
- when a query exists and matches a substring of the title:
  - that substring gets a background highlight color.

---

## Task Create/Edit Screen (`TaskFormScreen`)

File: `lib/screens/task_form_screen.dart`

Main responsibilities:

- Form fields:
  - Title (required)
  - Description (required)
  - Due date (required, chosen via date picker, stored as `yyyy-MM-dd`)
  - Status dropdown
  - Blocked by dropdown (list of existing tasks)
- Rules:
  - cannot pick itself as dependency:
    - blocker dropdown excludes `task.id`
- Save/Cancel:
  - Save triggers provider create/update
  - Cancel keeps a draft and returns
- Loading behavior:
  - Save button disabled while saving
  - shows small spinner inside Save button
  - create/update take ~2 seconds due to simulated delay in provider

### Draft feature (restore typed data)

Requirement:
> If user types and leaves screen: restore entered data

Implementation:
- `SharedPreferences` stores a JSON draft for **new tasks**
- key:
  - new task: `draft_task_new`
  - edit task: `draft_task_<id>` (kept, but restore is primarily used for new tasks)

What is stored:
- `title`, `description`, `dueDate`, `status`, `blockedBy`

When it saves:
- on every change via `TextEditingController` listeners
- when status or blockedBy dropdown changes

When it restores:
- on screen init (after preferences load)
- only restores if:
  - creating a new task AND fields are still pristine
  - so it won’t overwrite user edits

When it clears:
- after successful Save (create/update)

---

## Widgets

### `TaskCard`

File: `lib/widgets/task_card.dart`

Responsible for:
- Title (bold + optional highlight)
- Description (max 2 lines)
- Due date row
- Status chip with colors:
  - To-Do → grey
  - In Progress → blue-ish (primaryContainer)
  - Done → green
- Blocked visuals:
  - grey background + opacity
  - disabled tap
  - lock icon
  - “Blocked by …”
- Delete icon button

### `TaskSearchBar`

File: `lib/widgets/search_bar.dart`

Simple `TextField` with search icon and hint text.

### `StatusFilter`

File: `lib/widgets/status_filter.dart`

Dropdown to pick `TaskFilter` (All/To-Do/In Progress/Done).

---

## Theme and UI styling (`AppTheme`)

File: `lib/core/theme/app_theme.dart`

Key points:
- Material 3 enabled: `useMaterial3: true`
- Soft background: `scaffoldBackgroundColor`
- Inputs:
  - filled white fields
  - rounded border radius 12
- Cards:
  - rounded 12
  - no elevation

Note:
- The theme was adjusted to avoid type mismatches on `cardTheme`.
- Google Fonts is optional; this theme is dependency-free for typography.

---

## App startup (`main.dart`)

File: `lib/main.dart`

- Wraps the app in `ChangeNotifierProvider` so Provider can work.
- Applies `AppTheme.light()`.
- Sets home to `TaskListScreen`.

---

## How data flows (end-to-end)

1. App starts → `TaskListScreen` builds.
2. `TaskListScreen` watches `filteredTasksProvider`.
3. `filteredTasksProvider` depends on `tasksControllerProvider`.
4. First time `tasksControllerProvider` is read → `TasksController.build()` runs → reads SQLite via `TaskDao.fetchAll()`.
5. UI shows tasks.
6. Create/Edit:
   - form calls `createTask` / `updateTask`
   - provider simulates delay (2 seconds)
   - writes to SQLite
   - reloads list
7. Delete:
   - DAO clears dependent references
   - deletes row
   - list reloads


