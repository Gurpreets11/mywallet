# Privacy Policy

**Last updated:** August 12, 2026

This Privacy Policy explains what data My Wallet accesses, how it's used, and — most importantly — what it does *not* do with your information.

## Summary

My Wallet is an **offline-first, local-only** personal finance app. It does not have a backend server, does not collect analytics, and does not transmit your financial data anywhere. Everything you enter stays on your device.

## Data We Store

All data is stored locally in a SQLite database on your device, including:

- Expense records (amount, category, payment mode, notes, dates)
- Income records (amount, source, notes, dates)
- Investment records (name, type, invested amount, current value)
- Loan and EMI records (lender, amounts, payment history)
- App settings (currency, theme, reminder preferences)

None of this data is uploaded to a server, shared with third parties, or accessible to the app's developer. See [DATABASE.md](DATABASE.md) for the full schema.

## Device Permissions

My Wallet may request the following device permissions, used only for the stated purpose:

| Permission                | Why it's used                                                      |
| -------------------------- | --------------------------------------------------------------------- |
| **Biometric / Face & Fingerprint** | Optional app lock via `local_auth`, to prevent unauthorized access to your financial data on the device. |
| **Notifications**            | Local reminders (e.g., bill/EMI due dates) via `flutter_local_notifications`. Notifications are generated on-device and are not tied to any push notification service. |
| **Storage / File access**     | Only when you explicitly choose to export or share data (via `file_picker` / `share_plus`), e.g., generating a file to save or send. |

The app does not request location, contacts, camera, microphone, or network-related permissions beyond what the OS requires for the above.

## Secure Storage

- An optional PIN and/or biometric lock can be enabled to restrict access to the app.
- Sensitive configuration (such as lock settings) is stored using `flutter_secure_storage`, which relies on the Android Keystore or iOS Keychain — not the plain SQLite database.
- Your financial records themselves are stored in the local SQLite database, protected by your device's own storage security (device lock screen, disk encryption where supported by the OS).

## No Analytics or Tracking

My Wallet does not integrate any analytics, advertising, or crash-reporting SDKs that transmit data off-device. There are no third-party trackers bundled with the app.

## No Network Access for Financial Data

The current version of My Wallet does not sync, back up, or transmit your financial data over the network. If cloud backup or synchronization features are added in the future (see [ROADMAP.md](ROADMAP.md)), they will be:

- **Opt-in** — disabled by default
- Clearly documented, with this policy updated accordingly before release

## Data Retention & Deletion

- Your data persists on your device for as long as the app is installed.
- Uninstalling the app removes its local database and all stored records, in line with standard OS app-data behavior.
- There is no server-side copy to request deletion of, since none exists.
- If you want to preserve your data before uninstalling, use the app's export/share feature (where available) to save a copy first.

## Children's Privacy

My Wallet is a general-purpose finance tracking tool not directed at children and does not knowingly collect data from children, since it does not collect data from anyone in the first place — all information stays on the user's own device.

## Open Source

My Wallet's source code is publicly available at [github.com/Gurpreets11/mywallet](https://github.com/Gurpreets11/mywallet), so you (or anyone) can verify these privacy claims directly against the implementation.

## Changes to This Policy

If the app's data practices change (for example, if an opt-in cloud sync feature is introduced), this document will be updated and the change will be noted in [CHANGELOG.md](CHANGELOG.md).

## Contact

Questions about this policy can be raised via a [GitHub Issue](https://github.com/Gurpreets11/mywallet/issues) or by contacting the maintainer at [@Gurpreets11](https://github.com/Gurpreets11). For security-related concerns, see [SECURITY.md](SECURITY.md) instead.
