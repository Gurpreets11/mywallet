# My Wallet

A Flutter-based personal finance management application that helps you track expenses, income, investments, and loans — completely offline, using only local storage.

![Platform](https://img.shields.io/badge/platform-Android-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-in%20development-yellow)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Building the App](#building-the-app)
- [Database Design](#database-design)
- [Roadmap](#roadmap)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Overview

My Wallet is designed for people who want full control over their financial data without relying on the cloud. Every record — expenses, income, investments, loans — is stored locally on the device using SQLite, with no external servers involved.

---

## Features

### 💸 Expense Management
- Add, update, and delete expenses
- Expense categorization
- Payment mode tracking
- Monthly expense summary

### 💰 Income Management
- Track multiple income sources
- Salary and side-income management
- Income history and reports

### 📈 Investment Tracking
- Manage investments
- Track current value
- Profit and loss overview

### 🏦 Loan Management
- Loan tracking
- EMI payment history
- Outstanding balance calculation
- Loan repayment progress

### 📊 Dashboard & Analytics
- Monthly financial summary
- Income vs. expense overview
- Savings analysis
- Financial charts and reports

### 🔒 Security
- Local device storage only — no cloud sync
- Optional PIN lock
- Biometric authentication support

---

## Tech Stack

| Layer            | Technology                              |
| ---------------- | ---------------------------------------- |
| Framework        | Flutter                                  |
| Language         | Dart                                     |
| Local Database   | SQLite (`sqflite`)                       |
| State Management | Provider                                 |
| Charts           | `fl_chart`                               |
| Local Storage    | `shared_preferences`                     |
| Security         | `local_auth`, `flutter_secure_storage`   |
| Notifications    | `flutter_local_notifications`, `timezone`|
| Files & Sharing  | `file_picker`, `share_plus`              |
| Utilities        | `intl`, `permission_handler`, `package_info_plus`, `logger` |

---

## Project Structure

```
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

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.10.4`)
- Android Studio or VS Code with the Flutter/Dart plugins
- Android SDK / platform tools
- Git

Verify your setup:

```bash
flutter doctor
```

### Clone the repository

```bash
git clone https://github.com/Gurpreets11/mywallet.git
cd mywallet
```

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

---

## Building the App

**Debug APK**

```bash
flutter build apk --debug
```

**Release APK**

```bash
flutter build apk --release
```

Generated APK output:

```
build/app/outputs/flutter-apk/
```

---

## Database Design

| Table          | Purpose                       |
| -------------- | ------------------------------ |
| `expenses`     | Store expense records          |
| `incomes`      | Store income records            |
| `investments`  | Store investment details        |
| `loans`        | Store loan information          |
| `loan_payments`| Store EMI / payment history     |
| `categories`   | Store transaction categories    |
| `app_settings` | Store local app settings        |

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for completed phases and what's planned next (budgeting, recurring transactions, cloud backup, dark mode, and more).

---

## Documentation

- [ROADMAP.md](ROADMAP.md) — what's built and what's planned
- [ARCHITECTURE.md](ARCHITECTURE.md) — how the codebase is structured and how data flows through it
- [DATABASE.md](DATABASE.md) — SQLite schema reference
- [CHANGELOG.md](CHANGELOG.md) — release history
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute
- [SECURITY.md](SECURITY.md) — reporting vulnerabilities
- [PRIVACY.md](PRIVACY.md) — what data is collected and how it's handled
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — community guidelines

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## Security

This app stores all data locally on-device and does not transmit financial data to any server. See [SECURITY.md](SECURITY.md) for details on reporting vulnerabilities and how sensitive data is handled.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Author

Developed and maintained by [Gurpreets11](https://github.com/Gurpreets11), built with Flutter and Dart for scalable, offline-first personal finance management.