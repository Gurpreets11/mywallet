# Contributing to My Wallet

Thanks for your interest in contributing to My Wallet! This document outlines how to set up the project, propose changes, and submit pull requests.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Convention](#commit-message-convention)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

This project follows a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you're expected to uphold it.

## Getting Started

1. **Fork** the repository and clone your fork:
   ```bash
   git clone https://github.com/<your-username>/mywallet.git
   cd mywallet
   ```
2. **Install Flutter** (see [flutter.dev/get-started](https://docs.flutter.dev/get-started/install)) and verify:
   ```bash
   flutter doctor
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the app** on an emulator or connected device:
   ```bash
   flutter run
   ```

## Development Workflow

1. Create a new branch from `master`:
   ```bash
   git checkout -b feature/short-description
   ```
   Use a prefix that matches the change type: `feature/`, `fix/`, `docs/`, `refactor/`, `chore/`.
2. Make your changes, following the [coding guidelines](#coding-guidelines) below.
3. Run static analysis and tests before committing:
   ```bash
   flutter analyze
   flutter test
   ```
4. Commit your changes using the [commit convention](#commit-message-convention).
5. Push your branch and open a pull request against `master`.

## Coding Guidelines

- Follow the lint rules defined in `analysis_options.yaml` (based on `flutter_lints`). Run `flutter analyze` and resolve all warnings before submitting.
- Keep the existing project structure:
    - `core/` — shared constants, database setup, theming, utilities, reusable widgets
    - `data/` — models, repositories, services
    - `modules/` — one folder per feature (dashboard, expenses, income, investments, loans, settings)
    - `routes/` — app routing
- Prefer small, focused widgets and functions; avoid deeply nested widget trees.
- Use `Provider` for state management, consistent with the rest of the app.
- Add/extend unit or widget tests under `test/` for any new logic, especially database repositories and business logic.
- Do not commit generated files, build artifacts, or local `.env`/secrets.
- Write clear, descriptive variable and method names — avoid abbreviations that aren't already used in the codebase.

## Commit Message Convention

Please use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(optional scope): <short description>

[optional body]
[optional footer]
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`.

Examples:
```
feat(expenses): add monthly category filter
fix(loans): correct EMI outstanding balance calculation
docs: update README with build instructions
```

## Submitting a Pull Request

- Keep PRs focused on a single change or feature — smaller PRs are easier to review.
- Fill out the PR description: what changed, why, and how it was tested.
- Link any related issues (e.g., `Closes #12`).
- Ensure `flutter analyze` and `flutter test` pass locally.
- Include screenshots or a short screen recording for UI changes.
- Be responsive to review feedback — maintainers may request changes before merging.

## Reporting Bugs

Please open a [GitHub Issue](https://github.com/Gurpreets11/mywallet/issues) and include:

- App version / commit hash
- Device and OS version
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots or logs, if applicable

For security vulnerabilities, do **not** open a public issue — see [SECURITY.md](SECURITY.md) instead.

## Suggesting Features

Open a [GitHub Issue](https://github.com/Gurpreets11/mywallet/issues) with the `enhancement` label, describing:

- The problem the feature solves
- A proposed approach or UI (if applicable)
- Any alternatives you considered

Thanks again for helping improve My Wallet! 🙌