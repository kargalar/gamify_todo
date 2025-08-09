# Copilot instructions for this repo

Flutter app (Next Level / Gamify Todo) with offline-first Hive storage and optional Firebase sync. State via Provider singletons; navigation with Get; i18n via easy_localization; notifications/alarms via flutter_local_notifications + alarm.

## Big picture
- Startup (`General/init_app.dart`): load offline mode; if online init Firebase (`firebase_options.dart`), theme, Hive adapters (`Helper.registerAdapters`), EasyLocalization, NotificationService; configure Windows window or HomeWidget; check auth to set global `loginUser`; then load data + start `SyncManager` (when online).
- App shell (`main.dart`): MultiProvider + `GetMaterialApp`; entry chooser `Core/auth_wrapper.dart` (Firebase stream online, local fallback offline).

## Data and state
- Local store: `Service/hive_service.dart` (boxes per model). Models in `Model/*` are Hive types (`*.g.dart` generated). IDs tracked with SharedPreferences (e.g., `last_task_id`).
- Providers are singletons and also registered in `MultiProvider`; code often uses `TaskProvider()` directly.
- Mutations go through `Service/server_manager.dart` (persists to Hive + side-effects). Providers call `SyncManager().sync*` to push when online.
- Routines → tasks: `HiveService.createTasksFromRoutines()` creates daily tasks, marks overdue/failed, and schedules notifications.

## Firebase (online only)
- Guard all Firebase via `OfflineModeProvider.shouldDisableFirebase()`. In offline mode, `AuthService.auth` is null and sync is skipped.
- Auth: `AuthService` wraps FirebaseAuth but always maintains local `loginUser` (Hive). On sign-in/register it creates/loads a `UserModel` and runs `SyncManager.initialize()`.
- Sync: `SyncManager` + `FirestoreService` do full upload on startup then incremental download; listen to connectivity; start real-time listeners per collection when logged in.
- Firestore per-user layout: `users/{uid}/{tasks, task_logs, categories, traits, store_items, routines}` with mappers preserving enum/duration/time formats.

## Notifications and timers
- `NotificationService.scheduleNotification(...)` schedules notifications or full alarms. Use safe IDs (`id % 2147483647`); timer IDs via `getTimerNotificationId`. Tap navigates to `RoutineDetailPage` via `NavigatorService`/Get. Early reminders use `TaskModel.earlyReminderMinutes`.

## Conventions
- New model: add `@HiveType`, `toJson/fromJson`, run codegen, register adapter in `Helper.registerAdapters()`, CRUD in `HiveService`, Firestore mappers if synced, mutate via `ServerManager`, push via `SyncManager().syncX`.
- Task/routine edits: follow `TaskProvider.editTask` (preserve routine archive state, propagate template changes, manage logs/status, reschedule notifications).
- Don’t call Firebase directly from UI/Providers; respect offline mode and use existing services.

## Handy references
- Entry: `lib/main.dart`, `lib/Core/auth_wrapper.dart`, `lib/General/init_app.dart`.
- State: `lib/Provider/task_provider.dart`, `lib/Provider/offline_mode_provider.dart`.
- Data/Sync: `lib/Service/hive_service.dart`, `lib/Service/firestore_service.dart`, `lib/Service/sync_manager.dart`, `lib/Service/auth_service.dart`.
- Notifications/i18n/theme: `lib/Service/notification_services.dart`, `lib/Service/product_localization.dart`, `lib/General/app_theme.dart`.
