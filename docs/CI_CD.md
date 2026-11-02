# CI/CD Pipeline

This document explains the Continuous Integration and Continuous Delivery (CI/CD) pipeline used in the MyWallet project.

The project uses GitHub Actions to automatically analyze, test, build, and release the Flutter application.

## Overview

The current pipeline performs the following steps:

```text
Code Push
    |
    v
Checkout Source Code
    |
    v
Setup Flutter
    |
    v
Install Dependencies
    |
    v
Flutter Analyze
    |
    v
Flutter Test
    |
    v
Build Release APK
    |
    v
Upload APK Artifact
    |
    v
Push to Master?
    |
    +-- No --> End
    |
    +-- Yes
          |
          v
Create GitHub Release
          |
          v
Attach Versioned APK
```

## Workflow

The GitHub Actions workflow is responsible for automating the CI/CD process.

The workflow can be triggered by configured GitHub events such as:

- Push to configured branches
- Pull requests
- Push to the `master` branch for release creation

The workflow is located inside:

```text
.github/workflows/
```

## Pipeline Jobs

The pipeline is divided into multiple jobs:

```text
analyze-and-test
        |
        v
build-release-apk
        |
        v
create-github-release
```

Each job has a specific responsibility.

---

# Analyze and Test

The first stage validates the source code.

Typical checks include:

```bash
flutter analyze
flutter test
```

## Flutter Analyze

Static analysis checks the project for:

- Compilation problems
- Potential bugs
- Deprecated API usage
- Unused imports
- Unused variables
- Code quality issues
- Lint violations

Command:

```bash
flutter analyze
```

## Flutter Test

Automated tests are executed using:

```bash
flutter test
```

The build process depends on these checks passing successfully.

---

# Build Release APK

The `build-release-apk` job is responsible for generating the production APK.

This job depends on the analysis and test job:

```yaml
needs: analyze-and-test
```

This means the APK build will only start if the previous validation job succeeds.

The build command is:

```bash
flutter build apk --release
```

The default generated APK is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## APK Versioning

After the APK is generated, it can be renamed using:

- Application version from `pubspec.yaml`
- GitHub Actions build number

Example:

```text
MyWallet-v1.0.0-build-3.apk
```

The application version comes from:

```yaml
version: 1.0.0+1
```

The version name is:

```text
1.0.0
```

The GitHub Actions build number comes from:

```text
github.run_number
```

This helps identify the exact CI build that generated an APK.

---

# Upload APK Artifact

The generated APK is uploaded as a GitHub Actions artifact.

Example:

```yaml
- name: Upload Release APK
  uses: actions/upload-artifact@v4
```

Artifacts are useful for:

- Internal testing
- Downloading APKs from workflow runs
- Debugging build output
- Passing build files between jobs

The retention period can be configured in the workflow:

```yaml
retention-days: 7
```

After the retention period expires, the workflow artifact may be automatically removed.

---

# GitHub Release

A separate job is used to create a GitHub Release.

The release job depends on the APK build job:

```yaml
needs: build-release-apk
```

This ensures that a release is created only after the APK has been successfully generated.

The release job runs only when code is pushed to the production branch:

```yaml
if: github.ref == 'refs/heads/master'
```

## Release Flow

```text
Push to Master
       |
       v
CI Checks
       |
       v
Build Release APK
       |
       v
Download APK Artifact
       |
       v
Create GitHub Release
       |
       v
Attach APK
       |
       v
Share Release Link
```

Example:

```text
Tag: build-3
Release: MyWallet v1.0.0 - Build 3
APK: MyWallet-v1.0.0-build-3.apk
```

---

# Job Dependencies

GitHub Actions jobs can depend on other jobs using `needs`.

Example:

```yaml
build-release-apk:
  needs: analyze-and-test
```

Another example:

```yaml
create-github-release:
  needs: build-release-apk
```

Result:

```text
analyze-and-test
        |
        v
build-release-apk
        |
        v
create-github-release
```

If a required job fails, dependent jobs will not run.

---

# GitHub Actions Concepts Used

## Workflow

A workflow is the complete automation pipeline.

## Job

A job is a group of related steps.

Examples:

```text
analyze-and-test
build-release-apk
create-github-release
```

## Step

A step performs one specific task.

Examples:

```text
Checkout code
Install dependencies
Run tests
Build APK
Upload artifact
```

## Action

An action is reusable automation provided by GitHub or the community.

Examples:

```yaml
actions/checkout@v4
actions/upload-artifact@v4
actions/download-artifact@v4
```

## Runner

A runner is the machine that executes the workflow.

The project uses:

```yaml
runs-on: ubuntu-latest
```

---

# Artifacts vs Releases

| Artifact | GitHub Release |
|---|---|
| Temporary build output | Published application build |
| Used during CI/CD | Used for sharing releases |
| Configurable retention period | Remains until manually deleted |
| Available from workflow runs | Available from the Releases page |
| Mainly for internal use | Suitable for testers and clients |

For MyWallet:

```text
Artifact
    |
    v
Internal CI/testing use

GitHub Release
    |
    v
Shareable APK distribution
```

---

# Failure Behavior

The pipeline follows a dependency-based flow.

```text
Flutter Analyze Fails
        |
        v
Build and Release Jobs
        |
        v
Not Executed
```

Similarly:

```text
Tests Fail
        |
        v
APK Build
        |
        v
Not Executed
```

This prevents failing code from automatically reaching the release stage.

---

# Future Improvements

Potential future CI/CD improvements include:

- Automated semantic versioning
- Release creation using Git tags
- Automated changelog generation
- Code coverage reporting
- Integration tests
- Dependency security scanning
- Separate development, UAT, and production environments
- Firebase App Distribution
- Automated deployment to Google Play
- Build caching for faster CI execution
- Manual approval before production releases

## Related Documentation

- [README](../README.md)
- [CHANGELOG](../CHANGELOG.md)
- [CONTRIBUTING](../CONTRIBUTING.md)
- [Release Process](RELEASE_PROCESS.md)
