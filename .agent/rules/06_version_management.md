---
trigger: always_on
description: Versioning and Changelog standards.
category: governance
---
# 06 - Version Management

## 🧠 Rationale

Consistent versioning and a clear changelog are vital for project transparency and automation. This document defines the standards for Git commits, version tracking, and release documentation.

## 🛠️ Implementation

### 🛠️ Conventional Commits

All commits MUST follow the Conventional Commits specification. This enables automated changelog generation and version bumping.

**Format**: `<type>(<scope>): <description>`

**Types**:

- `feat`: A new feature (corresponds to PATCH or MINOR in SemVer).
- `fix`: A bug fix (corresponds to PATCH in SemVer).
- `docs`: Documentation changes.
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc.).
- `refactor`: A code change that neither fixes a bug nor adds a feature.
- `perf`: A code change that improves performance.
- `test`: Adding missing tests or correcting existing tests.
- `ci`: Changes to CI configuration scripts and tools (e.g., GH Actions, Molecule).
- `chore`: Changes to the build process or auxiliary tools.

### 📜 Changelog Standard

The `Changelog` file at the root must follow the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

- **Unreleased**: Always include an `## [Unreleased]` section at the top.
- **Sections**: Use `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` sub-headers.
- **Versioning**: Use [Semantic Versioning (SemVer) 2.0.0](https://semver.org/).

### 📦 Release Protocol

A release is an atomic operation consisting of:

1. **Version Bump**: Updating the `VERSION` file.
2. **Changelog Update**: Moving entries from `[Unreleased]` to a new version section with the current date.
3. **Commit**: A commit with the message `chore(release): <new-version>`.
4. **Tagging**: Creating a git tag matching the version (e.g., `v1.2.3`).

## ✅ Verification

- Check that the `Changelog` is updated before every release.
- Verify that `VERSION` matches the latest tag.
- Ensure all commits since the last release follow the standard.
