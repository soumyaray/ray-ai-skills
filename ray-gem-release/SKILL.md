---
description: Release a Ruby gem — bump version, commit, tag, and push to RubyGems
allowed-tools: Bash(git *), Bash(bundle *), Bash(rake *), Bash(gem *), Bash(grep *), Read, Edit, Grep, Glob, AskUserQuestion
---

# Release a Ruby gem

Guide the user through a full gem release: version bump, commit, tag, and publish to RubyGems.

## Prerequisites

Before starting, confirm the user has signed in to RubyGems:

> Make sure you have run `gem signin` before proceeding. If not, run `! gem signin` now.

## Steps

### 1. Preflight checks

- Run `bundle exec rake` (or the project's default task) to ensure tests and linting pass. Stop if anything fails.
- Run `git status` to confirm a clean working tree. If there are uncommitted changes, warn the user and stop.
- Check that the Rakefile includes `require "bundler/gem_tasks"`. If not, add it near the top of the Rakefile (after any existing requires) and inform the user.

### 2. Determine the version bump

- Find the current version (typically in `lib/**/version.rb`).
- Show the user the current version and ask which bump level they want:
  - **patch** (e.g., 1.0.0 -> 1.0.1) — bug fixes, minor changes
  - **minor** (e.g., 1.0.1 -> 1.1.0) — new features, backward-compatible
  - **major** (e.g., 1.1.0 -> 2.0.0) — breaking changes

### 3. Bump the version

- Edit the version file with the new version string.
- Run tests again (`bundle exec rake`) to make sure nothing broke.

### 4. Commit the version bump

- Stage only the version file.
- Commit with message: `docs: version bump to <new_version>`
- Do NOT reference AI in the commit message.

### 5. Release

- Ask the user for their RubyGems OTP code (for MFA).
- Run `rake release` to build the gem, create the git tag, and push commits/tag to the remote.
- The `rake release` task handles `git tag`, `git push`, and `gem build` automatically — but it does NOT handle `gem push` when MFA is required.
- After `rake release`, push the built gem with the OTP:

  ```shell
  gem push pkg/<gem_name>-<version>.gem --otp <OTP_CODE>
  ```

- Confirm the release was successful by checking the output.

### 6. Report

- Tell the user the release is complete and show the published version.

## Important

- Do NOT push to git or RubyGems without going through the steps above.
- Do NOT skip the test/lint preflight.
- Do NOT proceed past version bump if tests fail.
- Do NOT reference AI in any commit messages.
- If `rake release` fails on the `gem push` step due to OTP, that is expected — use `gem push` with `--otp` as described above.
