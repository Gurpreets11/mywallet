# Database Schema

My Wallet stores all data locally on-device using SQLite via the [`sqflite`](https://pub.dev/packages/sqflite) package. There is no remote database — the schema below is created and managed entirely by `core/database/` on first launch.

> **Note:** This document is the source of truth for the *intended* schema. If you change table/column definitions in `core/database/`, please update this file in the same PR so they stay in sync (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Overview

| Table            | Purpose                                    |
| ---------------- | -------------------------------------------- |
| `categories`      | Transaction categories used by expenses/income |
| `expenses`         | Expense records                              |
| `incomes`          | Income records                               |
| `investments`       | Investment holdings                          |
| `loans`             | Loan accounts                                |
| `loan_payments`      | EMI / repayment history per loan             |
| `app_settings`       | Local app configuration (e.g., PIN/biometric flag, currency, theme) |

## Entity Relationship Overview

```
categories 1───* expenses
categories 1───* incomes
loans      1───* loan_payments
```

- A **category** can be referenced by many expense or income records.
- A **loan** can have many payment records tracking its EMI/repayment history.
- `investments` and `app_settings` are currently standalone tables (no foreign-key relationships).

## Table Definitions

### `categories`

| Column      | Type    | Notes                                  |
| ----------- | ------- | ---------------------------------------- |
| `id`         | INTEGER | Primary key, autoincrement               |
| `name`       | TEXT    | Category name, unique                    |
| `type`       | TEXT    | `expense` or `income`                    |
| `icon`       | TEXT    | Icon identifier for UI display           |
| `color`      | TEXT    | Hex color code for UI display            |
| `is_default`  | INTEGER | `1` if a built-in/seeded category, `0` if user-created |
| `created_at`  | TEXT    | ISO-8601 timestamp                       |

### `expenses`

| Column        | Type    | Notes                                    |
| ------------- | ------- | ------------------------------------------ |
| `id`           | INTEGER | Primary key, autoincrement                 |
| `category_id`   | INTEGER | Foreign key → `categories.id`              |
| `amount`        | REAL    | Expense amount                             |
| `payment_mode`   | TEXT    | e.g., `cash`, `card`, `upi`, `bank_transfer` |
| `note`           | TEXT    | Optional description                       |
| `date`           | TEXT    | ISO-8601 date of the expense                |
| `created_at`     | TEXT    | ISO-8601 timestamp, record creation         |
| `updated_at`     | TEXT    | ISO-8601 timestamp, last modification       |

### `incomes`

| Column        | Type    | Notes                                    |
| ------------- | ------- | ------------------------------------------ |
| `id`           | INTEGER | Primary key, autoincrement                 |
| `category_id`   | INTEGER | Foreign key → `categories.id`              |
| `source`         | TEXT    | e.g., `salary`, `freelance`, `other`       |
| `amount`         | REAL    | Income amount                              |
| `note`           | TEXT    | Optional description                       |
| `date`           | TEXT    | ISO-8601 date of the income                |
| `created_at`     | TEXT    | ISO-8601 timestamp, record creation         |
| `updated_at`     | TEXT    | ISO-8601 timestamp, last modification       |

### `investments`

| Column          | Type    | Notes                                   |
| --------------- | ------- | ------------------------------------------ |
| `id`             | INTEGER | Primary key, autoincrement                 |
| `name`            | TEXT    | Investment name (e.g., fund/stock name)    |
| `type`            | TEXT    | e.g., `stocks`, `mutual_fund`, `fd`, `gold`, `other` |
| `invested_amount`  | REAL    | Total amount invested                      |
| `current_value`    | REAL    | Latest known value                         |
| `purchase_date`     | TEXT    | ISO-8601 date                              |
| `note`               | TEXT    | Optional description                       |
| `created_at`         | TEXT    | ISO-8601 timestamp, record creation         |
| `updated_at`         | TEXT    | ISO-8601 timestamp, last modification       |

### `loans`

| Column           | Type    | Notes                                  |
| ---------------- | ------- | ------------------------------------------ |
| `id`              | INTEGER | Primary key, autoincrement                 |
| `lender`            | TEXT    | Bank/institution or person name            |
| `principal_amount`   | REAL    | Original loan amount                       |
| `interest_rate`       | REAL    | Annual interest rate (%)                   |
| `tenure_months`        | INTEGER | Loan tenure in months                      |
| `emi_amount`            | REAL    | Monthly EMI amount                         |
| `start_date`             | TEXT    | ISO-8601 date                              |
| `status`                  | TEXT    | `active`, `closed`, `defaulted`            |
| `note`                     | TEXT    | Optional description                       |
| `created_at`               | TEXT    | ISO-8601 timestamp, record creation         |
| `updated_at`               | TEXT    | ISO-8601 timestamp, last modification       |

### `loan_payments`

| Column        | Type    | Notes                                    |
| ------------- | ------- | ------------------------------------------ |
| `id`           | INTEGER | Primary key, autoincrement                 |
| `loan_id`        | INTEGER | Foreign key → `loans.id`                   |
| `amount_paid`     | REAL    | Payment amount                             |
| `payment_date`     | TEXT    | ISO-8601 date                              |
| `payment_mode`      | TEXT    | e.g., `cash`, `bank_transfer`, `auto_debit` |
| `note`               | TEXT    | Optional description                       |
| `created_at`          | TEXT    | ISO-8601 timestamp, record creation         |

### `app_settings`

| Column       | Type    | Notes                                     |
| ------------ | ------- | -------------------------------------------- |
| `key`         | TEXT    | Setting key, primary key                     |
| `value`        | TEXT    | Setting value (stored as text; parsed by app) |

Typical keys: `pin_enabled`, `biometric_enabled`, `currency`, `theme_mode`, `reminder_enabled`.

> Sensitive values such as the PIN itself are **not** stored in `app_settings` — they live in `flutter_secure_storage`, backed by the platform Keystore/Keychain. See [SECURITY.md](SECURITY.md).

## Conventions

- **Primary keys**: all tables use an autoincrementing integer `id` (except `app_settings`, which is keyed by `key`).
- **Timestamps**: stored as ISO-8601 strings (`TEXT`), not Unix epoch integers, for readability and easy debugging.
- **Money fields**: stored as `REAL`. If precision issues arise, consider migrating to integer minor-units (e.g., cents/paise) in a future migration.
- **Soft vs. hard delete**: the app currently performs hard deletes (`DELETE FROM ...`). If undo/audit-trail support is added later, consider a `deleted_at` column instead.

## Migrations

Schema changes should be handled through `sqflite`'s `onUpgrade` callback in `core/database/`, incrementing the database version number. When adding or altering a table:

1. Increment the database version in `core/database/`.
2. Add the corresponding `ALTER TABLE` / `CREATE TABLE` statements in `onUpgrade`.
3. Update the table definitions in this document.
4. Add/update repository methods and models in `data/repositories/` and `data/models/`.
5. Add a test (using `sqflite_common_ffi`) covering the migration path from the previous version.

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — how repositories and the database layer fit into the overall app structure
- [SECURITY.md](SECURITY.md) — how sensitive values are protected outside this schema
- [PRIVACY.md](PRIVACY.md) — what data is collected and how it's used
