---
description: Perform a full project release (Version bump, Changelog update, Git Tag)
---

# Release Management Workflow

This workflow automates the process of tagging a new version, updating the changelog, and synchronizing with the repository.

## Steps

### 1. Pre-flight Validation

Run the formal pre-flight checks.

```bash
/release-preflight
```

### 2. Determine New Version

Check the current `VERSION` and decide on the new SemVer (Major.Minor.Patch).

// turbo

```bash
cat VERSION
```

### 3. Update VERSION File

Update the `VERSION` file with the new version number.

```bash
echo "<new-version>" > VERSION
```

### 4. Update Changelog

Move the `[Unreleased]` section content to a new version header with today's date in `Changelog`.

> [!NOTE]
> Ensure the date format is `YYYY-MM-DD`.

### 5. Commit Release

Commit the version bump and changelog update.

// turbo

```bash
git add VERSION Changelog
git commit -m "chore(release): <new-version>"
```

### 6. Create Git Tag

Create an annotated tag for the release.

// turbo

```bash
git tag -a v<new-version> -m "Release v<new-version>"
```

### 7. Push Release

Push the commit and the new tag to the remote.

// turbo

```bash
git push origin $(git branch --show-current) --follow-tags
```

## ✅ Verification

- Run `git tag -l` to see the new tag.
- Verify `Changelog` content for the new version section.
