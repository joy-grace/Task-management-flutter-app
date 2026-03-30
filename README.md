# Task Manager (Flutter + SQLite + Provider)

## Setup steps
- Install Flutter SDK (stable) and ensure `flutter` is on PATH
- From the project root, run:

```bash
flutter pub get
flutter run
```

## How to run the app
- `flutter run` (any supported device)
- Tasks are stored locally in SQLite (`task_manager.db`) using `sqflite` and `path_provider`.

## Track B mention (Dependency / Blocked tasks)
This app implements “Track B” dependency logic:
- If **Task B** has `blockedBy == Task A.id` **and** **Task A.status != "Done"**
  then **Task B is BLOCKED** and its UI is disabled + greyed out.

## Stretch goal implemented
- **Debounced search (300ms)**: search updates as you type.
- **Title highlight**: matching search text in task titles is highlighted.

## AI usage report
- Generated a clean Flutter structure under `lib/` following the requested architecture.
- Implemented Provider state management, SQLite persistence, draft restore, and modern Material UI.
- Ensured code passes local static checks available in the editor (lints) and kept complexity minimal.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
