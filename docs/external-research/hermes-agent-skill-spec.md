# External Research: Hermes Agent Skill Authoring Standards

> **Tier:** Tier 1-2 (Vendor Architecture & Ecosystem Specifications)  
> **Source:** NousResearch Hermes Agent Skill System & AgentSurgery Family  
> **Retrieved:** 2026-10-13  
> **Strategy:** `pattern-driven` + `codebase-first`  

---

## 1. Skill Taxonomy & Anatomy

Hermes skills follow a standard directory structure:
- `SKILL.md`: Root file containing YAML frontmatter and markdown instructions.
- `references/`: Topic-focused guides (e.g. `search-strategy-system.md`, `sarif-schema.md`). Kept under ~200 lines each to prevent umbrella bloating.
- `templates/`: Standalone templates for artifacts (HTML, JSON, Markdown, SARIF).
- `tests/`: Automated test suite validating frontmatter, body structure, and procedure compliance.

---

## 2. Frontmatter Constraints

- `name`: Lowercase, hyphen-delimited, max 64 characters.
- `description`: Strict <= 60 characters, starts with `"Use when..."` and ends with a period. First 57 chars act as self-contained trigger for the LLM tool selector.
- `version`: Strict SemVer (`X.Y.Z`).
- `platforms`: Explicit platform array `[linux, macos, windows]`.
- `metadata.hermes`: Contains `tags` and `related_skills` arrays.

---

## 3. Skill Composition & Orchestration

In the AgentSurgery family:
- **`Surgical-Investigation`** acts as the orchestrator. It does not re-implement low-level utilities; it sequences specialized skills:
  - `surgical-orchestration`: Subagent dispatching and message routing.
  - `surgical-implementation`: Code modification and automated execution pipeline.
  - `surgical-hermesdothealth`: Memory, config, and adapter health diagnostics.
  - `superpowers:verification-before-completion`: Verification gates before closing any task.

---

## 4. Cache TTL Rules

Caching external queries preserves agent tokens and latency across repeated invocations:
- **Tier 1 / Tier 2:** 7-day TTL (official specifications, RFCs, and repo discussions rarely change intraday).
- **Tier 3:** 3-day TTL (technical blogs, vendor posts).
- **Tier 4 / Tier 5:** 1-day TTL (community consensus, Reddit, social channels).
- **Cache Key:** `hash(strategy + normalized_query + project_fingerprint)`.
