# Testing

MyWallet has unit, database and widget tests in the `test/` folder.

## One-time setup

Add to `pubspec.yaml`:

```yaml
dependencies:
  local_auth: ^2.3.0          # biometric unlock

dev_dependencies:
  flutter_test:
    sdk: flutter
  sqflite_common_ffi: ^2.3.3  # runs the real SQLite database in tests
```

Then run `flutter pub get`.

Desktop SQLite is required for the database tests: Linux needs `libsqlite3-dev`
(`sudo apt install libsqlite3-dev sqlite3`); macOS and Windows work out of the box.

### Biometric platform setup

- **Android:** `MainActivity` must extend `FlutterFragmentActivity`, and
  `AndroidManifest.xml` needs `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.
- **iOS:** add `NSFaceIDUsageDescription` to `Info.plist`.

## Run

```
flutter test                      # everything
flutter test test/repositories    # one folder
flutter test --coverage           # coverage report in coverage/lcov.info
```

## Layout

| Folder | What it covers |
|--------|----------------|
| `test/helpers/` | `useFreshDatabase()` - gives each test an empty database with the real schema |
| `test/database/` | schema version, tables, columns, indexes, migrations |
| `test/core/` | validators, breakpoints, greeting, currency and date formatting, SHA-256, every app preference (defaults, saving, bad stored values, notifications) |
| `test/models/` | every model: map round trips and calculated values (budget, goal, net worth, insights, report) |
| `test/utils/` | investment ROI/profit and loan analytics helpers |
| `test/repositories/` | expenses, income, categories (add, rename, order, merge), budgets, goals, accounts and transfers, loans and EMIs, recurring schedules, investments and value history, yearly reports, net worth, month insights, the "all transactions" feed, master data and demo data seeding |
| `test/providers/` | navigation, expense, income, budget, report and master providers |
| `test/services/` | backup (files, pruning, device-only keys), restore (replace / merge, validation), data reset, automatic backup, CSV import, PIN lock |
| `test/widgets/` | PIN pad, empty/loading views, buttons, dialogs (delete, type-to-confirm, name), date-range chips, list header, undo snackbar, expense / income / loan / budget / dashboard cards |

## Writing a new database test

```dart
void main() {
  useFreshDatabase();            // new empty DB before every test

  test('adds an expense', () async {
    final id = await ExpenseRepository().insertExpense(...);
    expect(id, greaterThan(0));
  });
}
```

Use names starting with `Zz` for categories created in tests so they never clash with
the built-in seed categories.

## Not covered yet

- Features that call a platform plugin: file picker (CSV / PDF export, choosing a backup
  file), notifications scheduling, and the biometric prompt itself.
- Full-screen widget tests (list / add / detail screens) and end-to-end
  (`integration_test`) flows need a device or emulator.

The backup tests redirect `path_provider` to a temporary folder, so they never touch real
app storage.
