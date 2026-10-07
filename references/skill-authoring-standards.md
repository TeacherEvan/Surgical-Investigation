# Hermes Skill Authoring Standards — Reference

## Skill File Requirements

Every Hermes skill must have these components:

| Component | Required | Description |
|-----------|----------|-------------|
| `SKILL.md` | ✅ Yes | Skill definition with YAML frontmatter + Markdown body |
| `name` | ✅ Yes | Skill identifier (lowercase, hyphens, max 64 chars) |
| `description` | ✅ Yes | Must start with `"Use when ..."` (first 57 chars self-contained trigger) |
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
|---------|---------|
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

## Validation (Pre-Commit)

Before pushing a skill:
- [ ] `SKILL.md` frontmatter loads as YAML
- [ ] `description` starts with `"Use when"`
- [ ] `version` is valid SemVer
- [ ] `tags` and `related_skills` are non-empty arrays
- [ ] Template file exists (if referenced)
- [ ] Tests pass (`pytest`)
- [ ] File sizes within limits
