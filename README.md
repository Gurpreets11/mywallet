
# My Wallet

A Flutter-based personal finance management application designed to help users manage daily financial activities completely offline using local storage.

The app allows users to track:

* Expenses
* Income
* Investments
* Loans and EMI payments

Built with Flutter using scalable architecture and SQLite local database support.

---

# Features

## Expense Management

* Add, update, and delete expenses
* Expense categorization
* Payment mode tracking
* Monthly expense summary

## Income Management

* Track multiple income sources
* Salary and side income management
* Income history and reports

## Investment Tracking

* Manage investments
* Track current value
* Profit and loss overview

## Loan Management

* Loan tracking
* EMI payment history
* Outstanding balance calculation
* Loan repayment progress

## Dashboard & Analytics

* Monthly financial summary
* Income vs expense overview
* Savings analysis
* Financial charts and reports

## Security

* Local device storage
* Optional PIN lock
* Biometric authentication support

---

# Tech Stack

| Layer            | Technology                         |
| ---------------- | ---------------------------------- |
| Framework        | Flutter                            |
| Language         | Dart                               |
| Local Database   | SQLite (sqflite)                   |
| State Management | Provider                           |
| Charts           | fl_chart                           |
| Local Storage    | shared_preferences                 |
| Security         | local_auth, flutter_secure_storage |

---

# Project Structure

```text
lib/
│
├── core/
│   ├── constants/
│   ├── database/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── modules/
│   ├── dashboard/
│   ├── expenses/
│   ├── income/
│   ├── investments/
│   ├── loans/
│   └── settings/
│
├── routes/
│
└── main.dart
```

---

# Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  sqflite:
  path:
  path_provider:
  provider:
  fl_chart:
  intl:
  shared_preferences:
  local_auth:
  flutter_secure_storage:
```

---

# Getting Started

## Prerequisites

Install:

* Flutter SDK
* Android Studio / VS Code
* Android SDK
* Git

Verify Flutter installation:

```bash
flutter doctor
```

---

# Clone Repository

```bash
git clone <repository_url>
```

Move to project folder:

```bash
cd my_wallet
```

---

# Install Dependencies

```bash
flutter pub get
```

---

# Run Application

```bash
flutter run
```

---

# Build APK

## Debug APK

```bash
flutter build apk --debug
```

## Release APK

```bash
flutter build apk --release
```

Generated APK location:

```text
build/app/outputs/flutter-apk/
```

---

# Database Design

## Main Tables

| Table         | Purpose                      |
| ------------- | ---------------------------- |
| expenses      | Store expense records        |
| incomes       | Store income records         |
| investments   | Store investment details     |
| loans         | Store loan information       |
| loan_payments | Store EMI/payment history    |
| categories    | Store transaction categories |
| app_settings  | Store local app settings     |

---

# Development Roadmap

## Phase 1

* Project setup
* SQLite integration
* Base architecture

## Phase 2

* Expense module

## Phase 3

* Income module

## Phase 4

* Dashboard and analytics

## Phase 5

* Investment management

## Phase 6

* Loan and EMI tracking

## Phase 7

* Reports and charts

## Phase 8

* Security and optimization

---

# Future Enhancements

* Cloud backup
* Firebase sync
* Multi-device synchronization
* Budget planning
* Recurring transactions
* Bill reminders
* Export PDF/Excel
* OCR bill scanning
* AI-based spending insights
* Dark mode
* Multi-currency support

---

# Architecture Goals

* Clean architecture
* Modular code structure
* Reusable widgets
* Scalable database design
* Offline-first experience
* Maintainable codebase

---

# Author

Developed using Flutter and Dart for scalable offline personal finance management.

---

# License

This project is intended for personal learning and development purposes.

