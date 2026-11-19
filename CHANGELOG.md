# Changelog

All notable changes to **My Wallet** will be documented in this file.

The format is based on [Keep a ](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# myWallet Phase 14 - Categories, Undo, Duplicate & Date Presets

## Features Included:
- **Manage Categories** (Settings -> Manage categories): add, rename, hide/show and delete categories and subcategories, separately for Expense and Income. Uses the existing `categories` / `subcategories` tables - no migration.
- Inline **New category / New subcategory** links on the Add/Edit Expense and Add/Edit Income forms; the new item is selected automatically.
- **Undo after delete** (6-second snackbar) for expenses, income, loans and savings goals.
- **Duplicate** action in the expense and income card menu (opens the form pre-filled, dated today).
- **Date-range presets** in the expense and income filters: This month, Last month, Last 7 days, Last 30 days, This year (custom range picker still available).
- Home screen balance card label renamed from "Total Balance" to "This month's savings".

## Behaviour notes:
- A category/subcategory can only be deleted when nothing uses it (expenses, income, budgets, recurring schedules). Otherwise use **Hide**.
- Hidden categories no longer appear in the add forms, but old entries that use one still show it when edited, and it stays available in the list filters.
- Renaming a category also updates the stored `category_name` on expenses, budgets and recurring schedules (and `subcategory_name` on expenses), so reports stay consistent.
- Adding a category whose name matches a hidden one re-activates it instead of creating a duplicate.
- Deleting a loan now deletes its EMI payments in the same transaction (previously they were left behind as orphan "Loan EMI" rows); Undo restores the loan and its payments.
- Undo for expenses/income restores the row with its original id.

## Fixes:
- Loan and investment reminders: notification ids were built from `DateTime.now().millisecondsSinceEpoch`, which exceeds the 32-bit id limit on Android. Add Loan / Add Investment now call `NotificationService.rescheduleAll()` (loans use `loan.id`, SIPs use `1000000 + investment.id`).
- Edit screens for Income, Loans and Investments showed an error and a blank screen for entries whose saved value was not in the dropdown list (e.g. payment mode "Net Banking", loan type "Home Loan", an unlisted investment type). Dropdowns now include the saved value; loan types other than GIVEN open as BORROWED. The same safeguard was added to the expense payment-mode dropdown.

## Consistency:
- One shared delete confirmation (`confirmDelete` in `core/widgets/common_delete_dialog.dart`: warning icon, Cancel, red Delete) is used for expenses, income, loans, investments, goals, budgets, accounts, recurring schedules and categories.

## Files changed/new files only:
- lib/modules/categories/models/category_item.dart (new)
- lib/modules/categories/repositories/category_repository.dart (new)
- lib/modules/categories/screens/manage_categories_screen.dart (new)
- lib/modules/categories/widgets/name_dialog.dart (new)
- lib/modules/categories/widgets/quick_add.dart (new)
- lib/core/widgets/date_range_presets.dart (new)
- lib/core/widgets/common_delete_dialog.dart
- lib/core/utils/snackbar_utils.dart (`showUndo`)
- lib/data/repositories/master_repository.dart, lib/data/providers/master_provider.dart
- lib/modules/expenses/ and lib/modules/income/ (add forms, list screens, cards)
- lib/modules/loans/ (repository, provider, add/list screens)
- lib/modules/goals/ (repository, goals screen)
- lib/modules/investments/screens/ (add form, list screen)
- lib/modules/budgets/screens/budget_screen.dart, lib/modules/recurring/screens/recurring_screen.dart, lib/modules/accounts/screens/accounts_screen.dart (delete dialog)
- lib/modules/settings/setting_screen.dart, lib/modules/dashboard/widgets/balance_card.dart

## Database:
- No schema change (database version stays at 14).

## Integration:
1. Copy the files into the project, preserving the folder structure.
2. Run: `flutter pub get`, `dart format lib`, `flutter analyze`.


# myWallet Phase 13 - Dark Mode, Savings Goals, Budget Alerts, Recurring Upgrades & Search

## Features Included:
- **Dark mode**: Appearance setting (Light / Dark / System) in Settings; full dark theme; dashboard cards, PIN screens, reports, More screen and export sheet made theme-aware.
- **Savings goals**: create goals with a target amount and optional date, add/withdraw money, view history, "save per month" hint, goals summary card on the dashboard, Goals entry in the More screen and navigation rail.
- **Budget alerts**: local notification when a category budget reaches its alert percentage and again when the limit is reached (checked after saving an expense). Toggle in Settings.
- **Recurring**: account selector on schedules (generated entries carry the account) and a **Skip next** action.
- **Search**: search box on All Transactions (notes/remarks included) and a search shortcut on the home screen.

## Database:
- databaseVersion changes from 13 to 14 (`_applyV14Schema`, idempotent):
  - new tables `savings_goals`, `savings_goal_contributions`
  - new column `budgets.last_alert_level`
  - new column `recurring_transactions.account_id`
- Existing databases are upgraded automatically through onUpgrade.

## Files changed/new files only (key items):
- lib/core/theme/app_theme.dart, lib/main.dart
- lib/core/services/settings/app_preferences.dart (`pref_theme_mode`, `pref_budget_alerts_enabled`)
- lib/core/database/migrations.dart, lib/core/database/database_constants.dart
- lib/modules/goals/** (new)
- lib/modules/budgets/services/budget_alert_service.dart (new)
- lib/modules/recurring/** (model, repository, provider, screen)
- lib/modules/dashboard/** (goals card, search, theme-aware cards)
- lib/modules/settings/setting_screen.dart


# myWallet Phase 12 - Accounts

## Features Included:
- Accounts / wallets (Cash, Bank, etc.) with an opening balance and a default account.
- Live balance per account: opening balance + income + EMI received - expenses - EMI paid - investments +/- transfers.
- Transfers between accounts.
- Account selector on the Expense, Income, Loan EMI and Investment forms.
- Accounts screen with add / edit / delete (transactions of a deleted account move to the default account).

## Behaviour notes:
- Entries with no account (created before this feature) count towards the default account, so old data keeps working.
- Loan EMIs count as money in for GIVEN loans and money out for BORROWED loans.

## Database:
- databaseVersion changes from 12 to 13 (`_applyAccountsSchema`, idempotent):
  - new tables `accounts`, `account_transfers`
  - new column `account_id` on `expenses`, `incomes`, `loan_payments`, `investments`
  - one default "Cash" account is created if none exists

## Files changed/new files only:
- lib/modules/accounts/** (new: models, repositories, screens, widgets incl. `AccountDropdown`)
- lib/core/database/migrations.dart, lib/core/database/database_constants.dart
- Expense, income, loan and investment models / forms (account field)


# myWallet Phase 11 - All Transactions

## Features Included:
- "View all" on the home Recent Transactions card opens **All Transactions**.
- One date-wise feed combining expenses, income, loan EMI payments and investments.
- Backed by `transaction_feed_repository.dart`, which unions the source tables into a single list.

## Files changed/new files only:
- lib/modules/dashboard/screens/all_transactions_screen.dart (new)
- lib/modules/dashboard/repositories/transaction_feed_repository.dart (new)
- lib/modules/dashboard/models/ and dashboard screen (View all button)


# myWallet Phase 10 - Responsive Navigation & Loans Redesign

## Features Included:
- **Tablet / web navigation rail**: all destinations are shown in the rail (Home, Expenses, Income, Investments, Loans, Recurring, Reports, Budgets, Settings; Accounts and Goals were added to it in Phases 12-13). The **More** screen is now mobile-only; mobile layout is unchanged.
- Loans screens redesigned (summary card, loan cards, details) to match the expense/income styling.
- Expense and Income screens use the shared responsive content wrapper and pinned bottom action bar.

## Files changed/new files only:
- lib/main.dart
- lib/modules/navigation/screens/main_navigation_screen.dart
- lib/modules/loans/**


# myWallet Phase 9 - Settings

## Features Included:
- **Settings screen** with grouped sections: Preferences, Reminders, Security, Backup and Data.
- **Preferences**: date format, text size (selectable size applied app-wide) and Export to CSV (expenses, income or both, for a chosen period).
- **Reminders**: daily expense reminder with a configurable time, EMI reminders (a day before each EMI is due) and SIP reminders. Each can be switched on or off.
- **App lock (PIN)**: set, change and disable a PIN; the app asks for it on launch and when returning from the background. The PIN is stored hashed, not as plain text.
- **Backup Data**: exports all tables to a single JSON file (`my_wallet_backup.json`), with the backup version, database version and app version included.
- **Restore Data**: pick a backup file, review a summary (including a warning if it holds no transactions) and confirm before restoring.
- **Safety copies**: an automatic copy is saved before every restore or reset (the latest 5 are kept) and can be restored from Settings -> "Restore from safety copy".
- **Erase all data**: deletes everything and starts fresh, with a typed confirmation; a safety copy is taken first.
- Preferences are stored in the `app_metadata` table under `pref_*` keys. Backup and restore read the table list at runtime, so new tables are included automatically; device-only keys are excluded from backups.

## Files changed/new files only:
- lib/modules/settings/setting_screen.dart
- lib/modules/settings/screens/pin_setup_screen.dart
- lib/modules/settings/widgets/export_options_sheet.dart
- lib/core/services/settings/app_preferences.dart
- lib/core/services/backup/ (backup_service, restore_service, data_reset_service, backup_model, backup_result, backup_constants)
- lib/core/services/security/ (app_lock_service, sha256_lite)
- lib/core/services/export/csv_export_service.dart
- lib/core/widgets/type_to_confirm_dialog.dart, lib/core/widgets/app_lock_gate.dart

## Database:
- No schema change for this phase (preferences reuse `app_metadata`).



# myWallet Phase 8 - Reports & Analytics

## Features Included:
- Year selector with annual income, expense and net-savings totals.
- Monthly income-versus-expense bar chart.
- Category-wise expense pie chart and category totals.
- Monthly financial breakdown table.
- PDF report export.
- Excel-compatible CSV export.
- Reports entry in wide navigation and the mobile More screen.

## Files changed/new files only:
- lib/modules/reports/models/report_models.dart
- lib/modules/reports/repositories/report_repository.dart
- lib/modules/reports/providers/report_provider.dart
- lib/modules/reports/services/report_export_service.dart
- lib/modules/reports/screens/reports_screen.dart
- lib/main.dart
- lib/modules/navigation/screens/main_navigation_screen.dart
- lib/modules/dashboard/screens/more_screen.dart

## Integration:
1. Extract this ZIP into the Flutter project root and allow the files to merge.
2. No database migration is required.
3. No new pubspec dependencies are introduced. This implementation uses the existing fl_chart and file_picker packages already referenced by the supplied lib source.
4. Run:
   flutter pub get
   dart format lib
   flutter analyze
   flutter test

## Notes:
- Reports include only income and expense transactions recorded in the selected calendar year.
- Investments, loan principal/payments and transfers are not included in income/expense totals.
- CSV opens in Excel and other spreadsheet applications.
- PDF uses a built-in minimal PDF writer to avoid adding a PDF package. Non-ASCII characters in category labels are replaced in the PDF; the CSV retains UTF-8 text.
- Please test file saving on each target platform (Android/iOS/Web/Desktop), as file-picker save dialogs are platform-dependent.

# myWallet - Phase 7: Recurring transactions

This ZIP contains only new/modified files. Copy the contents of the ZIP into
your Flutter project root, preserving the folder structure.

## Included:
- New recurring transaction model, repository, provider and screen.
- SQLite schema migration from database version 11 to 12.
- Recurring menu item in mobile More and direct wide navigation.
- Due recurring entries generated at app startup and when the Recurring
  screen is refreshed/opened.

## How it works:
1. Add a recurring Expense or Income.
2. Select a category, amount, frequency, interval and start date.
3. Due occurrences are inserted into the existing expenses/incomes tables.
4. The occurrence table has a unique schedule/date constraint, preventing
   duplicate transaction generation if the app starts more than once.
5. Pausing stops future generation. Resuming continues from next_due_date.
6. Deleting a schedule does NOT delete already generated expense/income rows.

## Important behavior / limitations in this phase:
- Generation runs when the app launches and when the Recurring screen loads.
  It does not run in the background while the app is closed.
- Reminder days-before and local notification scheduling are not included
  in this implementation.
- The first version supports Daily, Weekly, Monthly and Yearly schedules.
- The first version supports creating, viewing, pausing, resuming and deleting
  schedules. Editing an existing schedule is not included.
- Generated entries use the selected category and payment mode. Subcategory
  selection is not included in recurring setup.
- Existing expense/income history remains unchanged.

## Database:
- databaseVersion changes from 11 to 12.
- Existing databases are upgraded using onUpgrade; no manual DB deletion is
  required. Do not uninstall the app or clear app data to apply the migration.


# MyWallet – Phase 6

## Monthly Budget Management
- Added monthly category-wise budgets with configurable 70%, 80%, 90% or 100% warning thresholds.
- Added spent, remaining and progress calculations based on expense records for the selected month.
- Added create, edit and delete budget flows.
- Added month navigation and a monthly budget overview.
- Added entry points from the dashboard (all screen sizes) and the mobile More screen.
- Added SQLite `budgets` table and `app_metadata` table; database version increased from 10 to 11.

## Development sample data
- Added `DemoDataSeedService` with sample Expenses, Income, Investments, Loans, Loan Payments and Budgets.
- Sample records are generated only in debug builds (`kDebugMode`).
- Seeding runs only once and only when the business tables are empty. Existing user data is never mixed with sample records.
- Release builds do not execute the demo seeding code.

## Integration
- Extract the ZIP into the project root. The archive contains only changed/new files under `lib/`.
- Run `flutter pub get`, `dart format lib`, `flutter analyze`, and `flutter test`.
- Existing databases upgrade automatically to version 11; no manual SQL is required.


# MyWallet – Phase 5

## Included changes

### Navigation
- Mobile keeps the existing four bottom destinations: Home, Expenses, Income and More.
- Tablet navigation rail now exposes all six main modules: Home, Expenses, Income, Investments, Loans and Settings.
- Desktop/web navigation exposes the same six destinations with the existing expanded sidebar behavior.
- Investments, Loans and Settings are direct destinations on tablet and desktop; More remains mobile-only.

### Forms and validation
- Income form now has responsive width, required category selection, positive amount validation, safe subcategory handling, date selection, recurring controls, save progress and duplicate-submit protection.
- Income edit preserves the original creation timestamp and selected category/subcategory names.
- Investment form now has consistent responsive layout, editable investment date, positive amount validation, SIP validation, save progress and duplicate-submit protection.
- Investment edit preserves creation timestamp and fields that are not editable in this form.
- Loan form now has responsive layout, field validation, editable start/next-EMI dates, save progress and duplicate-submit protection.
- Loan edit preserves creation timestamp, outstanding balance, payments and end date.
- Loan status handling is normalized so uppercase database statuses and title-case legacy/payment statuses display and behave consistently.
- Notification scheduling failures no longer make an already-saved loan or investment appear to have failed.

### Shared UI
- EmptyView now uses a shrink-wrapped, scrollable layout to prevent small-height RenderFlex overflows.
- Income detail page now scrolls on short screens.

## Files changed

- `lib/core/widgets/empty_view.dart`
- `lib/modules/navigation/screens/main_navigation_screen.dart`
- `lib/modules/income/screens/add_income_screen.dart`
- `lib/modules/income/screens/income_detail_screen.dart`
- `lib/modules/investments/screens/add_investment_screen.dart`
- `lib/modules/loans/screens/add_loan_screen.dart`
- `lib/modules/loans/providers/loan_provider.dart`
- `lib/modules/loans/repositories/loan_repository.dart`
- `lib/modules/loans/screens/loan_detail_screen.dart`
- `lib/modules/loans/widgets/loan_status_badge.dart`

## Integration

1. Extract this ZIP into the project root, allowing the `lib/` paths to merge with your existing files.
2. Run `flutter pub get`.
3. Run `dart format lib`.
4. Run `flutter analyze`.
5. Test mobile bottom navigation, tablet rail, desktop sidebar, and add/edit flows for Income, Investments and Loans.

No database schema or migration changes are included.

# Phase 4 – Investment Management UI Revamp

## Changed files only

- `lib/modules/investments/screens/investment_list_screen.dart`
  - Responsive constrained content layout for mobile/tablet/web.
  - Portfolio overview and investment allocation by current value.
  - Search, type/SIP filtering and sorting controls.
  - Responsive list/grid presentation and pull-to-refresh.
- `lib/modules/investments/widgets/investment_summary_card.dart`
  - Clear portfolio value, invested amount, profit/loss and ROI summary.
- `lib/modules/investments/widgets/investment_card.dart`
  - Cleaner investment cards with current value, invested value, gain/loss, ROI, SIP marker and contextual actions.
- `lib/modules/investments/screens/investment_detail_screen.dart`
  - Expanded details including available quantity, prices, maturity, interest and SIP fields.
- `lib/modules/investments/screens/add_investment_screen.dart`
  - Preserve original investment date and created timestamp during edits.
  - Save notes and preserve existing optional model fields when editing.
  - Dispose controllers and validate required name/amount fields.
- `lib/modules/investments/providers/investment_provider.dart`
  - Search notes and make latest sorting safe when an ID is null.

## Integration

Extract this ZIP into the Flutter project root. It contains only the changed investment files and this changelog. It does not include the full `lib` folder.

No database schema migration or new package is introduced.

## Validation

The ZIP contents were checked. A Flutter analyzer/build was not run because the complete project and Flutter SDK were not available in this environment. Run `flutter analyze` and test Android plus Chrome before merging.


# Phase 3 – Income Management UI Revamp

## Included
- Redesigned income list with responsive content width.
- Monthly income summary card.
- Search across amount, category, subcategory, payment mode, notes and recurring type.
- Category, payment mode and date-range filters.
- Sorting by newest, oldest, highest amount and lowest amount.
- Date grouping (Today, Yesterday and calendar date).
- Cleaner income cards with recurring indicator and contextual edit/delete menu.
- Delete confirmation.
- Responsive Add/Edit form width and controller disposal.
- Preserve the original `createdAt` value when editing an income record.
- Improved income detail presentation.
- Corrected monthly income total query to restrict the sum to the current local calendar month.

## Existing architecture preserved
- Provider state management.
- Existing IncomeModel and SQLite `incomes` table.
- Existing IncomeRepository CRUD methods.
- Existing category/subcategory master data provider.

## Integration
1. Back up the current `lib` folder.
2. Extract this ZIP and merge/replace its `lib` directory into the project. It includes the Phase 2 baseline plus Phase 3 income changes.
3. Keep `pubspec.yaml` unchanged.
4. Run `flutter pub get`, `flutter analyze`, then test on Android and Chrome.

## Validation note
The ZIP was structurally checked. A Flutter/Dart SDK and the complete application project were not available here, so no Flutter analyzer or platform build result is claimed.


# myWallet – Phase 2: Expense Management

## Included
- Reworked expense list with a compact monthly spending summary.
- Search across notes, category, subcategory, payment mode and amount.
- Category, payment mode and date-range filters.
- Sorting by newest, oldest, highest amount and lowest amount.
- Date-grouped transaction list (Today, Yesterday and calendar dates).
- Cleaner expense cards with a contextual Edit/Delete menu.
- Delete confirmation before removing an expense.
- Improved expense details showing category, subcategory, payment mode, date and notes.
- Responsive content width for mobile and web.
- Redesigned Add/Edit Expense form with validation, optional notes and date selection.
- Edit mode now loads the selected category's subcategories and preserves the original createdAt value.
- Fixed filtered-list indexing by consistently rendering the filtered list.
- Search now works locally across the displayed expense fields instead of querying only notes.
- Fixed current-month total query so transactions on the final day of the month are included.

## Files changed
- `lib/modules/expenses/providers/expense_provider.dart`
- `lib/modules/expenses/widgets/expense_card.dart`
- `lib/modules/expenses/screens/expense_list_screen.dart`
- `lib/modules/expenses/screens/add_expense_screen.dart`
- `lib/modules/expenses/screens/expense_detail_screen.dart`
- `lib/modules/expenses/repositories/expense_repository.dart`

## Database impact
No schema changes or migrations. Existing Provider, Repository, Model and SQLite table are retained.

## Validation
The package is based on the Phase 1 fixed `lib` archive. A Flutter SDK and complete project files (`pubspec.yaml`, platform folders) were not available in this environment, so `flutter analyze`, Android build and web build must be run in the user's full project.


# myWallet – Phase 1 UI Foundation

## Included
- Set the application to use the finalized light theme by default.
- Refreshed the light theme color palette and Material 3 component styling.
- Added shared mobile/tablet/desktop breakpoints.
- Added a reusable max-width responsive content wrapper.
- Replaced the always-bottom navigation with adaptive navigation:
  - Mobile: bottom NavigationBar.
  - Tablet: NavigationRail with labels (starting at 600 logical pixels).
  - Desktop: extended NavigationRail with myWallet branding.
- Updated the More screen grid to adapt to available width and use clearer menu cards.

## Files added
- `lib/core/utils/app_breakpoints.dart`
- `lib/core/widgets/app_responsive_content.dart`

## Files updated
- `lib/main.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/modules/navigation/screens/main_navigation_screen.dart`
- `lib/modules/dashboard/screens/more_screen.dart`

## Not included in this phase
- No database schema changes.
- No changes to expense, income, investment, loan or dashboard business logic.
- No new feature modules yet.

## Validation note
The supplied archive contained only the `lib/` directory and did not include `pubspec.yaml` or the complete Flutter project. Flutter/Dart SDK executables were not available in this execution environment, so `flutter analyze` and device/browser builds could not be run here. Please run them in the full project before merging these changes.


## [Unreleased]

### Added
- Nothing yet.

### Changed
- Nothing yet.

### Fixed
- Nothing yet.

---

## [1.1.0] - 2026-11-19

### Added
- Manage Categories (add, rename, hide, delete categories and subcategories for expenses and income) with inline "New category / New subcategory" links on the forms.
- Accounts with per-account balances and transfers; account selector on the transaction forms.
- Savings goals with progress, contributions and a dashboard summary card.
- Budget alerts (local notifications) and a Settings toggle.
- Dark mode (Light / Dark / System).
- All Transactions screen with search; global search shortcut on the home screen.
- Undo after delete (expenses, income, loans, goals), Duplicate for expenses and income, date-range presets in filters.
- Responsive navigation rail on tablet and web.
- Recurring transactions: account selector and "Skip next".

### Changed
- Home balance card label "Total Balance" is now "This month's savings".
- Deleting a loan also deletes its EMI payments.
- One shared delete confirmation dialog across the app.
- Database version 14 (see DATABASE.md).

### Fixed
- Edit screens for Income, Loans and Investments failing when the saved dropdown value was not in the list.
- Loan/investment reminder notification ids exceeding the 32-bit limit.

---

## [1.0.0] - 2026-08-12

### Added
- Initial release of My Wallet.
- Expense management: add, update, delete, categorize, and track payment mode.
- Income management: multiple income sources, salary/side-income tracking, income history.
- Investment tracking: manage investments, track current value, view profit/loss.
- Loan management: loan tracking, EMI payment history, outstanding balance, repayment progress.
- Dashboard & analytics: monthly summary, income vs. expense overview, savings analysis, charts.
- Local SQLite database (`sqflite`) for fully offline data storage.
- Optional PIN lock and biometric authentication (`local_auth`, `flutter_secure_storage`).
- Local notifications support (`flutter_local_notifications`, `timezone`).
- File picker and share functionality (`file_picker`, `share_plus`).

---

## Release Notes Guide

When adding a new entry, use the following categories as needed:

- **Added** — new features
- **Changed** — changes in existing functionality
- **Deprecated** — soon-to-be-removed features
- **Removed** — removed features
- **Fixed** — bug fixes
- **Security** — vulnerability fixes

[Unreleased]: https://github.com/Gurpreets11/mywallet/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Gurpreets11/mywallet/releases/tag/v1.0.0