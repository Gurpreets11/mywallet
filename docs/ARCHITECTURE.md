# Architecture

This document explains how My Wallet's codebase is organized and why, so contributors can find (and add) code in the right place.

## Guiding Principles

- **Offline-first** — no network layer; all reads/writes go through the local SQLite database.
- **Separation of concerns** — UI, business/data logic, and low-level infrastructure are kept in distinct layers.
- **Feature-based modules** — screens and widgets are grouped by feature (expenses, income, loans, etc.) rather than by widget type, so related code lives together.
- **Single source of truth for state** — `Provider` mediates between the UI and the data layer; widgets don't talk to the database directly.

## High-Level Layers

```
UI (modules/*)
   │  reads/writes via
   ▼
State Management (Provider)
   │  calls
   ▼
Repositories (data/repositories)
   │  use
   ▼
Services / Database (data/services, core/database)
   │
   ▼
SQLite (sqflite)
```

## Folder Responsibilities

### `core/`
Cross-cutting code used across features:

- `core/constants/` — app-wide constants (route names, table names, static config values).
- `core/database/` — SQLite setup: database initialization, schema creation, and migrations. See [DATABASE.md](DATABASE.md) for the schema itself.
- `core/theme/` — colors, text styles and the light and dark theme definitions (`app_theme.dart`). Widgets read colors from `Theme.of(context).colorScheme` so both themes work.
- `core/services/` — app-level services: backup/restore, CSV export, app lock (PIN), notifications, and `settings/app_preferences.dart` (theme, font size, date format and reminder toggles, stored under `pref_*` keys in `app_metadata`).
- `core/utils/` — pure helper functions (formatting, date/currency utilities, validators).
- `core/widgets/` — reusable UI components shared across multiple modules (buttons, cards, form fields, charts wrappers). Notable shared pieces: `common_delete_dialog.dart` (`confirmDelete`, the one delete confirmation used everywhere), `date_range_presets.dart` (This month / Last 7 days ... chips used by the expense and income filters), `app_responsive_content.dart`.
- `core/utils/snackbar_utils.dart` — `showSnackbar` and `showUndo` (snackbar with an UNDO action).

### `data/`
The data layer, independent of UI:

- `data/providers/` and `data/repositories/` also hold the shared master data (`MasterProvider` / `MasterRepository`: category and subcategory lists for the forms and filters).
- `data/models/` — plain Dart classes representing domain entities (`Expense`, `Income`, `Investment`, `Loan`, `LoanPayment`, `Category`), including `fromMap`/`toMap` (or similar) conversions to/from SQLite rows.
- `data/repositories/` — one repository per entity/table. Repositories are the only place that issue SQL queries; they expose typed methods (e.g., `addExpense`, `getExpensesForMonth`) to the rest of the app.
- `data/services/` — supporting services that aren't pure CRUD — e.g., authentication/biometrics (`local_auth`), secure storage (`flutter_secure_storage`), notifications (`flutter_local_notifications`), file export/sharing (`file_picker`, `share_plus`).

### `modules/`
Feature-first UI, one folder per feature:

- `modules/dashboard/` — home screen, summary cards (balance, goals), charts (`fl_chart`), recent transactions, **All Transactions** screen with search (`transaction_feed_repository.dart` unions expenses, income, loan payments and investments into one date-wise feed). `DashboardProvider` is the central holder of dashboard state (recent transactions, account balances, goal progress).
- `modules/expenses/` — expense list, add/edit forms, category filters.
- `modules/income/` — income sources, add/edit forms, income history.
- `modules/investments/` — investment list, current value tracking, profit/loss views.
- `modules/loans/` — loan list, EMI schedules, repayment progress.
- `modules/settings/` — app settings (appearance, reminders, budget alerts, backup/restore, PIN lock) and the entry to Manage Categories.
- `modules/budgets/` — monthly category budgets; `services/budget_alert_service.dart` sends the local notification after an expense is saved.
- `modules/recurring/` — recurring expense/income schedules (account selector, pause/resume, Skip next); due entries are generated at app start and when the screen opens.
- `modules/reports/` — yearly reports, charts, PDF/CSV export.
- `modules/accounts/` — accounts/wallets, balances, transfers, and the shared `AccountDropdown` used by the transaction forms.
- `modules/goals/` — savings goals, contributions and history.
- `modules/categories/` — **Manage Categories** (`CategoryRepository`, Expense/Income tabs, rename/hide/delete) and the inline `quick_add.dart` helpers used on the add forms.
- `modules/navigation/` — adaptive shell: bottom navigation + More screen on mobile, a navigation rail with every destination on tablet and web.

Each module typically contains its own `models/`, `repositories/`, `providers/`, `screens/` and `widgets/` folders (so in practice most repositories live inside their module, next to the provider that uses them).

### `routes/`
Centralized route definitions and navigation setup, so screens are registered in one place rather than scattered across modules.

### `main.dart`
App entry point: initializes the database, registers `Provider`s, sets up theming, and defines the root widget/navigator.

## Data Flow Example: Adding an Expense

1. User submits the "Add Expense" form in `modules/expenses/`.
2. The screen calls a method on the expenses `Provider` (e.g., `addExpense(expense)`).
3. The provider calls `ExpenseRepository.addExpense(expense)` in `data/repositories/`.
4. The repository converts the `Expense` model to a map and inserts it via the database helper in `core/database/`.
5. On success, the provider updates its in-memory state and notifies listeners.
6. The UI rebuilds (e.g., the expense list and dashboard summary) to reflect the new record.

No network calls occur at any point in this flow — everything resolves against the local SQLite file.

## Cross-Cutting Behaviours

- **Navigation**: `main_navigation_screen.dart` switches layout by screen width. Mobile keeps the bottom bar plus a More screen; tablet and web show every destination in a rail (the More screen is mobile-only).
- **Theming**: `AppPreferences` is a `ChangeNotifier`; `MaterialApp` listens to it and applies `themeMode` (light / dark / system).
- **Categories**: type id `0` = expense, `1` = income. Hidden categories are filtered out of the add forms (`MasterRepository` takes `alsoIncludeId` so an old entry still shows its own hidden category) and included in list filters (`includeInactive`). Because expenses, budgets and recurring schedules store a copy of the category name, `CategoryRepository.renameCategory` updates those copies in the same operation.
- **Accounts**: a transaction with no `account_id` belongs to the default account. Balances are computed from the transaction tables, not stored.
- **Delete + Undo**: lists confirm with `confirmDelete`, delete, then show `SnackbarUtils.showUndo`. Undo re-inserts the removed model with its original id (expenses, income); loans are deleted together with their payments and restored together; goals are restored with their contributions.
- **Notifications**: `NotificationService.rescheduleAll()` is the single place that schedules loan EMI reminders (id = loan id), SIP reminders (id = `1000000 + investment id`) and the daily reminder; save screens call it instead of creating ad-hoc ids.
- **Forms with stored dropdown values**: dropdowns that edit old data must include the saved value even if it is not in the standard list, otherwise Flutter throws an assertion and the screen is blank.

## State Management

- `Provider` is used for app-wide and per-module state (e.g., `ChangeNotifierProvider` per feature).
- Providers own business logic that coordinates repositories (e.g., recalculating a loan's outstanding balance after a payment), keeping that logic out of widgets.
- Widgets should stay presentation-focused: read state via `context.watch`/`Consumer`, and delegate actions to the provider rather than implementing logic inline.

## Security-Related Architecture

- `local_auth` gates access to the app (PIN/biometric) at the navigation layer, typically before the root/dashboard route is shown.
- `flutter_secure_storage` is used for anything sensitive that isn't a financial record itself (e.g., lock settings), keeping it out of the plain SQLite database.
- See [SECURITY.md](SECURITY.md) and [PRIVACY.md](PRIVACY.md) for more on data handling.

## Testing Strategy

- Unit tests (`test/`) target `data/repositories/` and `core/utils/` logic, using `sqflite_common_ffi` to run SQLite in a non-mobile test environment.
- Widget tests cover key module screens (forms, list rendering, validation states).
- Contributors adding a repository method or business-logic change should add a corresponding test — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Extending the Architecture

When adding a new feature:

1. Add a model in `data/models/` (if it maps to a new table, document it in [DATABASE.md](DATABASE.md)).
2. Add a repository in `data/repositories/` for its data access.
3. Add a module folder under `modules/` for its screens/widgets and provider.
4. Register any new routes in `routes/`.
5. Add reusable UI pieces to `core/widgets/` only if they're genuinely shared across modules — otherwise keep them local to the module.
