# Changelog

All notable changes to **My Wallet** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Placeholder section for upcoming changes.

### Changed
- Placeholder section for upcoming changes.

### Fixed
- Placeholder section for upcoming changes.

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