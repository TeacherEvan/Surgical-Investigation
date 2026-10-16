# Hermes Skill Authoring Standards — Reference

## Skill File Requirements

Every Hermes skill must have these components:

| Component | Required | Description |
| ----------- | ---------- | ------------- |
| `SKILL.md` | ✅ Yes | Skill definition with YAML frontmatter + Markdown body |
| `name` | ✅ Yes | Skill identifier (lowercase, hyphens, max 64 chars) |
| `description` | ✅ Yes | Strict ≤60 chars, starts with `"Use when ..."`, ends with a period (first 57 chars = self-contained trigger) |
| `version` | ✅ Yes | SemVer format (e.g., `1.1.0`) |
| `author` | ✅ Yes | Creator attribution |
| `license` | ✅ Yes | MIT or other open license |
| `platforms` | ✅ Yes | `[linux, macos, windows]` or subset |
| `tags` | ✅ Yes | At least one tag from Hermes taxonomy |
| `related_skills` | ✅ Yes | Qualified names (`superpowers:executing-plans`) |

## Frontmatter Rules

```yaml
---
name: my-skill
description: "Use when ..."
version: 1.0.0
author: Name
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [tag1, tag2]
    related_skills: [skill:name, superpowers:name]
---
```

## Body Structure (Standard Sections)

| Section | Purpose |
| --------- | --------- |
| `# Skill Name` | Title |
| `## Overview` | What the skill does (1-3 sentences) |
| `## When to Use` | Trigger conditions (bulleted) |
| `## When Not to Use` | Counter-indications |
| `## Procedure` | Step-by-step instructions |
| `## Related Skills` | References with explanation |
| `## Author` | Attribution |
| `## License` | License reference |

## Skill Size Limits

- SKILL.md: ~100KB max
- Individual templates: ~50KB max
- Total skill directory: ~200KB max

## Reference Files (Optional)

References in `references/` support the skill's procedures. They should be:

- Named clearly (`search-strategy-system.md`, `feature-recommendation-format.md`)
- Focused on a single topic
- Referenced by the skill's steps

## Template Files (Optional)

Templates in `templates/` generate reports or artifacts. They should:

- Be standalone (no external dependencies unless documented)
- Include clear variable placeholders
- Be tested by the skill's tests

## Test Requirements

Every skill should have:

- `tests/skills/test_<skill>_skill.py`
- Tests for frontmatter validity
- Tests for body structure
- Tests for template presence
- Tests for key procedure steps

## Mirrored Installs — the Repo Is the Source of Truth

A skill installed into an agent (Hermes, OpenCode, Gemini CLI, Antigravity) is a
**copy**. Copies drift, and the drift is invisible: after v1.2.0 was pushed, the
Hermes install looked correct at the top level but its `docs/` tree was stale, and
three other installs still ran v1.1.0 with only 1 of 4 templates. Every check
passed, because nothing compared bytes.

Rules:

- **Edit the repo, never an install.** A direct install edit is either clobbered by
  the next sync or never reaches the repo at all — and the next session inherits
  the confusion.
- **Give the repo a `scripts/sync-skill.sh`** with `check` / `sync` / `verify`
  modes (rsync `--itemize-changes`). `check` and `verify` must be read-only and
  exit non-zero when stale, so drift fails loudly instead of quietly.
- **Mirror only skill assets** — `SKILL.md`, `README.md`, `templates/`,
  `references/`, `docs/`. Exclude repo-only dirs (`.github/`, `tests/`,
  `scripts/`) and any `_archive*` path: past investigation *outputs* are not skill
  assets and must not propagate into every install.
- **Verify with a second mechanism** (`diff -r`, `cmp`, `md5sum`) rather than the
  sync script's own report. A tool's self-report is not evidence.
- **Back up the installs before the first sync** — `tar czf` every target, because
  the first mirror run both overwrites stale files and prunes the ones no longer
  in the repo.

## Validation (Pre-Commit)

Before pushing a skill:

- [ ] `SKILL.md` frontmatter loads as YAML
- [ ] `description` starts with `"Use when"`, is ≤60 chars, and ends with a period
- [ ] `version` is valid SemVer
- [ ] `tags` and `related_skills` are non-empty arrays
- [ ] Template file exists (if referenced)
- [ ] Tests pass (`pytest`)
- [ ] File sizes within limits
- [ ] Every install re-synced (`scripts/sync-skill.sh sync && scripts/sync-skill.sh verify`)
