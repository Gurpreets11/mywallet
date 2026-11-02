# Release Process

This document describes how application releases are created and distributed for MyWallet.

The current release process uses GitHub Actions to automatically build the APK and create a GitHub Release.

## Release Overview

```text
Development
    |
    v
Code Changes
    |
    v
Update Version
    |
    v
Update CHANGELOG
    |
    v
Merge / Push to Master
    |
    v
GitHub Actions
    |
    v
Analyze Code
    |
    v
Run Tests
    |
    v
Build Release APK
    |
    v
Create GitHub Release
    |
    v
Attach Versioned APK
    |
    v
Share Release Link
```

# Versioning

MyWallet uses the Flutter version defined in `pubspec.yaml`.

Example:

```yaml
version: 1.0.0+1
```

The version contains two parts:

```text
1.0.0+1
|     |
|     +-- Build number
|
+-------- Version name
```

The user-facing application version is:

```text
1.0.0
```

The build number is:

```text
1
```

## Version Format

The project aims to follow semantic versioning:

```text
MAJOR.MINOR.PATCH
```

### MAJOR

Increase when making major or breaking changes.

Example:

```text
1.0.0 -> 2.0.0
```

### MINOR

Increase when adding significant new features.

Example:

```text
1.0.0 -> 1.1.0
```

### PATCH

Increase when fixing bugs or making small improvements.

Example:

```text
1.0.0 -> 1.0.1
```

---

# Before Creating a Release

Before pushing a release to the production branch, complete the following checks.

## 1. Update Application Version

Update `pubspec.yaml`.

Example:

```yaml
version: 1.1.0+2
```

## 2. Update CHANGELOG

Add the changes to `CHANGELOG.md`.

Example:

```markdown
## [1.1.0]

### Added
- Budget planning

### Changed
- Improved dashboard performance

### Fixed
- Fixed incorrect monthly expense calculation
```

## 3. Run Code Formatting

```bash
dart format .
```

## 4. Run Static Analysis

```bash
flutter analyze
```

Resolve important errors and warnings before creating a release.

## 5. Run Tests

```bash
flutter test
```

All tests should pass.

## 6. Build the APK Locally (Optional)

```bash
flutter build apk --release
```

This is optional because GitHub Actions builds the APK again.

---

# Creating a Release

The current release process is triggered by pushing code to the `master` branch.

```text
feature branch
      |
      v
develop
      |
      v
master
```

When code reaches `master`, the GitHub Actions workflow performs the release process.

## Pipeline Execution

The pipeline performs:

```text
1. Checkout source code
2. Setup Flutter
3. Install dependencies
4. Run flutter analyze
5. Run flutter test
6. Build release APK
7. Rename APK
8. Upload APK artifact
9. Create GitHub Release
10. Attach APK to release
```

If analysis or tests fail, the release APK is not created.

---

# APK Naming

The APK is automatically renamed.

Format:

```text
MyWallet-v<version>-build-<github-run-number>.apk
```

Example:

```text
MyWallet-v1.0.0-build-3.apk
```

The version comes from `pubspec.yaml`, and the build number comes from:

```text
github.run_number
```

---

# GitHub Release Naming

The current GitHub Release format is:

```text
Tag: build-<run-number>
```

Example:

```text
build-3
```

The release name is:

```text
MyWallet v1.0.0 - Build 3
```

The release contains:

```text
Assets
└── MyWallet-v1.0.0-build-3.apk
```

---

# Sharing a Release

After the GitHub Actions workflow completes successfully:

```text
Repository
    |
    v
Releases
    |
    v
Select Latest Release
```

The release page can be shared with testers, team members, and clients.

A release page follows this pattern:

```text
https://github.com/Gurpreets11/mywallet/releases/tag/build-3
```

The direct APK download URL follows this pattern:

```text
https://github.com/Gurpreets11/mywallet/releases/download/build-3/MyWallet-v1.0.0-build-3.apk
```

The release page is generally recommended because it provides:

- Release information
- Version details
- Release notes
- Downloadable APK assets

---

# Testing a Release APK

After downloading the APK:

1. Open the APK file on an Android device.
2. Allow installation from the selected source if required.
3. Install the application.
4. Verify the application version.
5. Perform basic smoke testing.
6. Report any issues through the project's issue tracking process.

Recommended testing areas:

- Application launch
- Authentication
- Dashboard loading
- Expense management
- Income management
- Investment management
- Loan management
- Data persistence

---

# Release Checklist

Before merging or pushing to `master`:

- [ ] Application version updated in `pubspec.yaml`
- [ ] `CHANGELOG.md` updated
- [ ] Code formatted using `dart format .`
- [ ] `flutter analyze` completed successfully
- [ ] `flutter test` completed successfully
- [ ] Feature changes manually tested
- [ ] No sensitive information committed
- [ ] Documentation updated if required

After the GitHub Actions workflow:

- [ ] CI pipeline completed successfully
- [ ] Release APK generated
- [ ] APK artifact uploaded
- [ ] GitHub Release created
- [ ] Correct APK attached
- [ ] APK downloaded and tested
- [ ] Release link shared with testers if required

---

# Current Release Strategy

The current release strategy is:

```text
Development Branches
        |
        v
CI Validation
        |
        v
Build APK
        |
        v
Master Branch
        |
        v
GitHub Release
```

Currently, every successful configured `master` push can create a GitHub Release.

This is suitable for internal testing and continuous delivery.

---

# Future Release Strategy

As the project grows, the release process can be improved to use Git tags.

Example:

```text
v1.0.0
v1.0.1
v1.1.0
v2.0.0
```

A future flow could be:

```text
Update Version
      |
      v
Update CHANGELOG
      |
      v
Create Git Tag
      |
      v
Push Tag
      |
      v
GitHub Actions
      |
      v
Build APK
      |
      v
Create Versioned GitHub Release
```

Example:

```bash
git tag v1.1.0
git push origin v1.1.0
```

This would allow releases to directly correspond to application versions instead of CI build numbers.

## Related Documentation

- [CI/CD Pipeline](CI_CD.md)
- [CHANGELOG](../CHANGELOG.md)
- [README](../README.md)
