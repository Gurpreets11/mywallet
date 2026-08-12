# Security Policy

## Overview

My Wallet is an **offline-first** personal finance application. All financial data (expenses, income, investments, loans) is stored **locally on the user's device** using SQLite (`sqflite`). The app does not transmit financial data to any remote server, and there is currently no cloud sync or backend component.

Because the app handles sensitive personal financial data, security is a priority even though everything stays on-device.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                 |

Only the latest released version receives security fixes. Please update to the latest release before reporting an issue.

## Data Handling

- **Local storage only** — all records live in a local SQLite database on the device.
- **Secure storage** — sensitive values (e.g., PIN, auth tokens/settings) use `flutter_secure_storage`, which relies on Android Keystore / iOS Keychain.
- **Authentication** — optional PIN lock and biometric authentication (`local_auth`) can be enabled to restrict access to the app.
- **No analytics or third-party tracking** is bundled with the core app.
- **No network transmission** of financial data occurs in the current version.

## Reporting a Vulnerability

If you discover a security vulnerability in My Wallet, please **do not open a public GitHub issue**. Instead:

1. Report it privately via [GitHub Security Advisories](https://github.com/Gurpreets11/mywallet/security/advisories/new) for this repository, **or**
2. Contact the maintainer directly through their GitHub profile ([@Gurpreets11](https://github.com/Gurpreets11)) to arrange a secure disclosure channel.

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (proof of concept, if possible)
- The affected version/commit
- Any suggested remediation, if known

### What to expect

- Acknowledgement of your report as soon as reasonably possible
- An assessment of the issue and, if confirmed, a plan for a fix
- Credit in the release notes/changelog, if you'd like (or anonymity, if preferred)

We ask that you give us a reasonable amount of time to address the issue before any public disclosure.

## Best Practices for Users

- Enable the optional **PIN lock** or **biometric authentication** in Settings.
- Keep your device's OS up to date, since local data protection depends on platform-level security (Keystore/Keychain, device lock screen).
- Back up your data manually before uninstalling or switching devices — deleting the app removes the local database.
- Only install the app from trusted sources (this repository or an official release build).

## Out of Scope

- Vulnerabilities requiring physical access to an already-unlocked, compromised device
- Issues in third-party dependencies that are already publicly disclosed and unpatched upstream (please report those to the respective package maintainers as well)