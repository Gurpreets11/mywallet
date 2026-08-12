# Roadmap

This document tracks the development direction for My Wallet. It's a living document — dates aren't fixed commitments, and priorities may shift based on feedback and available time.

For released changes, see [CHANGELOG.md](CHANGELOG.md). To propose something new, open a [feature request](.github/ISSUE_TEMPLATE/feature_request.yml).

## Status Legend

- ✅ Done
- 🚧 In progress
- 📋 Planned
- 💡 Idea / under consideration

---

## Completed Phases

| Phase | Focus                          | Status |
| ----- | ------------------------------- | :----: |
| 1     | Project setup & SQLite integration | ✅ |
| 2     | Expense module                  | ✅ |
| 3     | Income module                   | ✅ |
| 4     | Dashboard and analytics         | ✅ |
| 5     | Investment management           | ✅ |
| 6     | Loan and EMI tracking           | ✅ |
| 7     | Reports and charts              | 🚧 |
| 8     | Security and optimization        | 🚧 |

---

## Near-Term (Next Release)

- 📋 Polish reports/charts (export-ready views, better empty/error states)
- 📋 Security hardening: enforce PIN/biometric prompt on app resume, audit `flutter_secure_storage` usage
- 📋 Performance pass on database queries for large transaction histories
- 📋 Expand test coverage for repositories and business logic in `data/`

## Mid-Term

- 💡 Budget planning (set monthly/category budgets with progress tracking)
- 💡 Recurring transactions (auto-log recurring expenses/income)
- 💡 Bill reminders via local notifications
- 💡 Export data to PDF/Excel
- 💡 Dark mode

## Long-Term / Exploratory

- 💡 Cloud backup & restore (opt-in, encrypted)
- 💡 Multi-device synchronization
- 💡 OCR-based bill/receipt scanning
- 💡 AI-based spending insights
- 💡 Multi-currency support

---

## How Priorities Are Set

Roadmap items move up based on:

1. Core functionality gaps (things needed for the app to be reliably usable offline)
2. Security and data-integrity concerns
3. Frequently requested features (via GitHub issues)
4. Effort vs. impact for a solo/small-team maintained project

## Contributing to the Roadmap

Have an idea or want to help build one of these? Check [CONTRIBUTING.md](CONTRIBUTING.md) and open an issue or discussion before starting significant work, so effort isn't duplicated.