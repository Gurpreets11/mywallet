# Database Schema

My Wallet stores all data locally on-device using SQLite via the [`sqflite`](https://pub.dev/packages/sqflite) package. There is no remote database — the schema below is created and managed entirely by `core/database/` (`migrations.dart`, `database_constants.dart`).

> **Note:** This document describes the schema as implemented in `core/database/migrations.dart`. If you change table/column definitions there, update this file in the same PR so they stay in sync (see [CONTRIBUTING.md](CONTRIBUTING.md)).

- Database file: `my_wallet.db`
- Current schema version: **14**

## Overview

| Table                        | Purpose                                                        |
| ---------------------------- | -------------------------------------------------------------- |
| `transaction_types`          | Transaction type lookup used by categories                     |
| `categories`                 | Expense and income categories (editable from Manage Categories) |
| `subcategories`              | Subcategories belonging to a category                          |
| `expenses`                   | Expense records                                                |
| `incomes`                    | Income records                                                 |
| `investments`                | Investment holdings, including SIP details                     |
| `loans`                      | Loans taken or given                                           |
| `loan_payments`              | EMI / repayment history per loan                               |
| `budgets`                    | Monthly category budgets and alert state                       |
| `recurring_transactions`     | Recurring expense / income schedules                           |
| `recurring_occurrences`      | Which dates a schedule has already generated                   |
| `accounts`                   | Accounts / wallets with opening balance                        |
| `account_transfers`          | Transfers between accounts                                     |
| `savings_goals`              | Savings goals                                                  |
| `savings_goal_contributions` | Money added to / withdrawn from a goal                         |
| `app_metadata`               | Key/value store for app preferences (`pref_*` keys) and metadata |

## Entity Relationship Overview

```
transaction_types 1───* categories 1───* subcategories
categories    1───* expenses / incomes / budgets / recurring_transactions
subcategories 1───* expenses / incomes
loans         1───* loan_payments
recurring_transactions 1───* recurring_occurrences
savings_goals 1───* savings_goal_contributions
accounts      1───* expenses / incomes / loan_payments / investments / recurring_transactions   (via account_id)
accounts      1───* account_transfers                                                           (from / to)
```

- `account_id` is **nullable**. A `NULL` (or an id that no longer exists) means "the default account", so data created before accounts existed keeps working.
- Expenses, budgets and recurring schedules also store a denormalised `category_name` (and expenses a `subcategory_name`). Renaming a category in Manage Categories updates these copies. `incomes` has no name columns; names are joined from `categories` / `subcategories`.

## Table Definitions

### `transaction_types`

| Column      | Type    | Notes                      |
| ----------- | ------- | -------------------------- |
| `id`        | INTEGER | Primary key, autoincrement |
| `type_name` | TEXT    | Type name                  |

The app treats type `0` as **expense** and `1` as **income** when loading categories.

### `categories`

| Column                | Type    | Notes                                              |
| --------------------- | ------- | -------------------------------------------------- |
| `id`                  | INTEGER | Primary key, autoincrement                         |
| `transaction_type_id` | INTEGER | Foreign key → `transaction_types.id` (expense / income) |
| `category_name`       | TEXT    | Display name                                       |
| `icon_name`           | TEXT    | Optional icon identifier                           |
| `color_code`          | TEXT    | Optional color                                     |
| `is_active`           | INTEGER | `1` = visible, `0` = hidden (default `1`)          |
| `created_at`          | TEXT    | ISO-8601 timestamp                                 |

Hidden (`is_active = 0`) categories are not offered in the add forms but remain on existing records and in list filters. A category is only deleted when no expense, income, budget or recurring schedule uses it.

### `subcategories`

| Column             | Type    | Notes                                  |
| ------------------ | ------- | -------------------------------------- |
| `id`               | INTEGER | Primary key, autoincrement             |
| `category_id`      | INTEGER | Foreign key → `categories.id`          |
| `subcategory_name` | TEXT    | Display name                           |
| `is_active`        | INTEGER | `1` = visible, `0` = hidden (default `1`) |
| `created_at`       | TEXT    | ISO-8601 timestamp                     |

### `expenses`

| Column             | Type    | Notes                                          |
| ------------------ | ------- | ---------------------------------------------- |
| `id`               | INTEGER | Primary key, autoincrement                     |
| `amount`           | REAL    | Expense amount                                 |
| `category_id`      | INTEGER | Foreign key → `categories.id`                  |
| `subcategory_id`   | INTEGER | Foreign key → `subcategories.id`, nullable     |
| `category_name`    | TEXT    | Denormalised category name                     |
| `subcategory_name` | TEXT    | Denormalised subcategory name, nullable        |
| `date`             | TEXT    | ISO-8601 date                                  |
| `payment_mode`     | TEXT    | e.g. `Cash`, `UPI`, `Card`, `Bank`             |
| `notes`            | TEXT    | Optional description                           |
| `created_at`       | TEXT    | ISO-8601 timestamp                             |
| `account_id`       | INTEGER | → `accounts.id`, nullable (added in v13)       |

### `incomes`

| Column           | Type    | Notes                                        |
| ---------------- | ------- | -------------------------------------------- |
| `id`             | INTEGER | Primary key, autoincrement                   |
| `amount`         | REAL    | Income amount                                |
| `category_id`    | INTEGER | Foreign key → `categories.id`                |
| `subcategory_id` | INTEGER | Foreign key → `subcategories.id`, nullable   |
| `date`           | TEXT    | ISO-8601 date                                |
| `payment_mode`   | TEXT    | e.g. `Cash`, `UPI`, `Bank`                   |
| `notes`          | TEXT    | Optional description                         |
| `is_recurring`   | INTEGER | `1` if created as recurring (default `0`)    |
| `recurring_type` | TEXT    | Recurrence label, nullable                   |
| `created_at`     | TEXT    | ISO-8601 timestamp                           |
| `account_id`     | INTEGER | → `accounts.id`, nullable (added in v13)     |

### `investments`

| Column                | Type    | Notes                                    |
| --------------------- | ------- | ---------------------------------------- |
| `id`                  | INTEGER | Primary key, autoincrement               |
| `investment_type`     | TEXT    | e.g. mutual fund, stocks, FD             |
| `investment_name`     | TEXT    | Investment name                          |
| `investment_platform` | TEXT    | Broker / platform, nullable              |
| `invested_amount`     | REAL    | Total amount invested                    |
| `current_value`       | REAL    | Latest known value                       |
| `quantity`            | REAL    | Nullable                                 |
| `purchase_price`      | REAL    | Nullable                                 |
| `current_price`       | REAL    | Nullable                                 |
| `investment_date`     | TEXT    | ISO-8601 date                            |
| `maturity_date`       | TEXT    | Nullable                                 |
| `interest_rate`       | REAL    | Nullable                                 |
| `is_sip`              | INTEGER | `1` for a SIP (default `0`)              |
| `sip_amount`          | REAL    | SIP amount, nullable                     |
| `sip_date`            | INTEGER | Day of month for the SIP, nullable       |
| `notes`               | TEXT    | Optional description                     |
| `created_at`          | TEXT    | ISO-8601 timestamp                       |
| `account_id`          | INTEGER | → `accounts.id`, nullable (added in v13) |

### `loans`

| Column               | Type    | Notes                                           |
| -------------------- | ------- | ----------------------------------------------- |
| `id`                 | INTEGER | Primary key, autoincrement                      |
| `loan_type`          | TEXT    | `BORROWED` or `GIVEN` (anything else is treated as borrowed) |
| `person_name`        | TEXT    | Lender / borrower                               |
| `principal_amount`   | REAL    | Original amount                                 |
| `interest_rate`      | REAL    | Annual interest rate (%), nullable              |
| `emi_amount`         | REAL    | Monthly EMI, nullable                           |
| `next_emi_date`      | TEXT    | ISO-8601 date, nullable                         |
| `tenure_months`      | INTEGER | Nullable                                        |
| `start_date`         | TEXT    | ISO-8601 date                                   |
| `end_date`           | TEXT    | Nullable                                        |
| `total_paid`         | REAL    | Default `0`                                     |
| `outstanding_amount` | REAL    | Remaining amount                                |
| `loan_status`        | TEXT    | `ACTIVE`, `CLOSED` or `OVERDUE` (default `ACTIVE`) |
| `notes`              | TEXT    | Optional description                            |
| `created_at`         | TEXT    | ISO-8601 timestamp                              |

### `loan_payments`

| Column           | Type    | Notes                                        |
| ---------------- | ------- | -------------------------------------------- |
| `id`             | INTEGER | Primary key, autoincrement                   |
| `loan_id`        | INTEGER | Foreign key → `loans.id`                     |
| `payment_amount` | REAL    | Payment amount                               |
| `payment_date`   | TEXT    | ISO-8601 date                                |
| `payment_mode`   | TEXT    | e.g. `Cash`, `UPI`, `Bank`                   |
| `remarks`        | TEXT    | Optional note                                |
| `created_at`     | TEXT    | ISO-8601 timestamp                           |
| `account_id`     | INTEGER | → `accounts.id`, nullable (added in v13)     |

Deleting a loan from the app also deletes its `loan_payments` rows (in one transaction).

### `budgets`

| Column             | Type    | Notes                                                      |
| ------------------ | ------- | ---------------------------------------------------------- |
| `id`               | INTEGER | Primary key, autoincrement                                 |
| `category_id`      | INTEGER | → `categories.id`                                          |
| `category_name`    | TEXT    | Denormalised category name                                 |
| `amount`           | REAL    | Budget for the month                                       |
| `month`, `year`    | INTEGER | Budget period; unique with `category_id`                   |
| `alert_percentage` | INTEGER | Percent of the budget that triggers an alert (default `80`) |
| `last_alert_level` | INTEGER | `0` none sent, `1` near limit sent, `2` limit reached sent (added in v14) |
| `created_at`       | TEXT    | ISO-8601 timestamp                                         |

### `recurring_transactions`

| Column             | Type    | Notes                                              |
| ------------------ | ------- | -------------------------------------------------- |
| `id`               | INTEGER | Primary key, autoincrement                         |
| `title`            | TEXT    | Schedule title                                     |
| `transaction_type` | TEXT    | Expense or income                                  |
| `amount`           | REAL    | Amount per occurrence                              |
| `category_id`      | INTEGER | → `categories.id`                                  |
| `category_name`    | TEXT    | Denormalised category name                         |
| `payment_mode`     | TEXT    | Nullable                                           |
| `notes`            | TEXT    | Nullable                                           |
| `frequency`        | TEXT    | Daily, Weekly, Monthly or Yearly                   |
| `interval_value`   | INTEGER | Repeat every N periods (default `1`)               |
| `start_date`       | TEXT    | ISO-8601 date                                      |
| `end_date`         | TEXT    | Nullable                                           |
| `next_due_date`    | TEXT    | Next occurrence to generate ("Skip next" advances this) |
| `status`           | TEXT    | `ACTIVE`, `PAUSED` or `COMPLETED` (default `ACTIVE`) |
| `created_at`       | TEXT    | ISO-8601 timestamp                                 |
| `account_id`       | INTEGER | → `accounts.id`, nullable (added in v14)           |

### `recurring_occurrences`

| Column                     | Type    | Notes                                                        |
| -------------------------- | ------- | ------------------------------------------------------------ |
| `id`                       | INTEGER | Primary key, autoincrement                                   |
| `recurring_transaction_id` | INTEGER | → `recurring_transactions.id`, `ON DELETE CASCADE`           |
| `occurrence_date`          | TEXT    | Unique with `recurring_transaction_id` (prevents duplicates) |
| `transaction_type`         | TEXT    | Expense or income                                            |
| `generated_transaction_id` | INTEGER | Id of the generated expense / income row                     |
| `created_at`               | TEXT    | ISO-8601 timestamp                                           |

### `accounts`

| Column            | Type    | Notes                                       |
| ----------------- | ------- | ------------------------------------------- |
| `id`              | INTEGER | Primary key, autoincrement                  |
| `name`            | TEXT    | Account name                                |
| `account_type`    | TEXT    | Type code, e.g. `BANK` (cash, bank, wallet...) |
| `opening_balance` | REAL    | Starting balance (default `0`)              |
| `is_default`      | INTEGER | `1` for the default account                 |
| `created_at`      | TEXT    | ISO-8601 timestamp                          |

A default "Cash" account is created if none exists. Balance = opening balance + income + EMI received (GIVEN loans) − expenses − EMI paid (BORROWED loans) − investments + transfers in − transfers out.

### `account_transfers`

| Column            | Type    | Notes                          |
| ----------------- | ------- | ------------------------------ |
| `id`              | INTEGER | Primary key, autoincrement     |
| `from_account_id` | INTEGER | Source account                 |
| `to_account_id`   | INTEGER | Destination account            |
| `amount`          | REAL    | Transferred amount             |
| `date`            | TEXT    | ISO-8601 date                  |
| `notes`           | TEXT    | Optional                       |
| `created_at`      | TEXT    | ISO-8601 timestamp             |

### `savings_goals`

| Column          | Type    | Notes                        |
| --------------- | ------- | ---------------------------- |
| `id`            | INTEGER | Primary key, autoincrement   |
| `name`          | TEXT    | Goal name                    |
| `target_amount` | REAL    | Amount to reach              |
| `target_date`   | TEXT    | Optional deadline            |
| `created_at`    | TEXT    | ISO-8601 timestamp           |

### `savings_goal_contributions`

| Column       | Type    | Notes                                              |
| ------------ | ------- | -------------------------------------------------- |
| `id`         | INTEGER | Primary key, autoincrement                         |
| `goal_id`    | INTEGER | → `savings_goals.id`                               |
| `amount`     | REAL    | Amount saved (negative values are withdrawals)     |
| `date`       | TEXT    | ISO-8601 date                                      |
| `notes`      | TEXT    | Optional                                           |
| `created_at` | TEXT    | ISO-8601 timestamp                                 |

Saved amount for a goal = sum of its contributions. Goals do not affect income, expenses or account balances. Deleting a goal removes its contributions (Undo restores both).

### `app_metadata`

| Column       | Type | Notes                                                       |
| ------------ | ---- | ----------------------------------------------------------- |
| `meta_key`   | TEXT | Primary key                                                 |
| `meta_value` | TEXT | Value stored as text                                        |

Preference keys are prefixed `pref_` (e.g. `pref_theme_mode`, `pref_font_size`, `pref_date_format`, `pref_daily_reminder_enabled`, `pref_daily_reminder_time`, `pref_emi_reminders_enabled`, `pref_sip_reminders_enabled`, `pref_budget_alerts_enabled`).

> Sensitive values such as the PIN are **not** stored here — see [SECURITY.md](SECURITY.md).

## Version History

| Version | Change |
| ------- | ------ |
| 11 → 12 | Recurring transactions (`recurring_transactions`, `recurring_occurrences`) |
| 12 → 13 | Accounts (`accounts`, `account_transfers`, `account_id` on expenses, incomes, loan_payments, investments, default Cash account) |
| 13 → 14 | Savings goals (`savings_goals`, `savings_goal_contributions`), `budgets.last_alert_level`, `recurring_transactions.account_id` |

Manage Categories, undo, duplicate and date presets did **not** change the schema.

## Conventions

- **Primary keys**: all tables use an autoincrementing integer `id` (except `app_metadata`, keyed by `meta_key`).
- **Timestamps**: ISO-8601 strings (`TEXT`).
- **Money fields**: `REAL`.
- **Deletes**: hard deletes. The UI offers an in-session **Undo** by re-inserting the removed rows with their original ids (expenses, income, loans with payments, goals with contributions).

## Migrations

Schema changes go through `sqflite`'s `onUpgrade` in `core/database/migrations.dart`:

1. Increment `databaseVersion` in `database_constants.dart`.
2. Add an idempotent `_applyVXSchema` helper (`CREATE TABLE IF NOT EXISTS`, and add columns only after checking `PRAGMA table_info`), and call it from both `onCreate` and `onUpgrade` (`if (oldVersion < X)`).
3. Update this document.
4. Update models and repositories, and add a migration test using `sqflite_common_ffi`.
5. Backup / restore reads table names at runtime, so new tables are included automatically; keep device-only keys out of backups.

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SECURITY.md](SECURITY.md)
- [PRIVACY.md](PRIVACY.md)
