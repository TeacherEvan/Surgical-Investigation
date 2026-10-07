# Surgical-Investigation

**Deep project investigation with strategy-driven search, multi-format output, and skill composition.**

Part of the [AgentSurgery](https://github.com/TeacherEvan/AgentSurgery) surgical-skills set — alongside [surgical-orchestration](https://github.com/TeacherEvan/surgical-orchestration), [Surgical-Implementation](https://github.com/TeacherEvan/Surgical-Implementation), and [Surgical-HermesDotHealth](https://github.com/TeacherEvan/Surgical-HermesDotHealth).

## What It Does

When activated, Surgical-Investigation prompts you to choose between two modes:

### Investigator Mode

Performs a comprehensive investigation of your project and generates a report in **4 output formats**:

- **HTML** (default) — Interactive report with 4 Mermaid diagrams (Backend, Frontend, Research, Entire-Project), sticky navigation, follow-up request modal, IMPLEMENT button
- **JSON** — Structured data for programmatic consumption, CI integration
- **Markdown** — Human-readable summary for Git docs, PR descriptions, wiki
- **SARIF** — Standard SARIF 2.1.0 for GitHub Code Scanning, VS Code, static analysis tooling

**Investigation includes:**

- **Search Strategy Selection (Step 0.5)** — 8 strategies: `codebase-first`, `targeted-docs`, `error-driven`, `rule-id-driven`, `cve-driven`, `pattern-driven`, `community-pulse`, `full-sweep` (auto-inferred from your request)
- **Search Budgets** — Per-strategy limits on subagents, sources, time (prevents runaway calls)
- **Source Credibility Scoring** — 5 tiers (official docs=1.0 → unverified=0.2), surfaced in findings
- **Incremental Cache (Step 0.7)** — Caches external research per project (TTL by tier), reuses + refreshes only stale entries
- **Dependency audit** — Versions, security status, maintenance status
- **Best practices assessment** — Code quality, architecture, testing, security, performance, docs
- **Implementation optimality check** — Algorithms, complexity, resources, alternatives, scalability
- **Agent files audit** — Skills, memory, config, docs, kanban, tools
- **External research** — Strategy-driven search across official docs, GitHub, Stack Overflow, technical blogs, communities
- **Feature recommendations** — Specific, actionable suggestions with endpoints, controls, webhooks, widgets
- **Interactive refinement** — After initial search: deeper on finding #N, skip source type, change strategy, export findings only
- **Quick Search Mode** — Lightweight: Step 0.5 → Step 7 only, returns synthesized findings, no report, no build

Report saved to `docs/surgical-investigation-report.{html|json|md|sarif}`.

### Project-Manager Mode (YOLO Build)

Performs the same investigation, then **builds directly** based on findings — fixes issues, updates dependencies, refactors suboptimal code, adds recommended features. No report for review. Ends with:

> This was the best I can do!

## Search Strategies

| Strategy | Description | Best For | Budget (subagents/sources/time) |
|----------|-------------|----------|--------------------------------|
| `codebase-first` | Local files only; external only if code points outward | Finding usage, tracing logic | 2 / N/A / 60s |
| `targeted-docs` | Official docs, GitHub issues for specific library/feature | "How to implement X with Y" | 3 / 5 / 90s |
| `error-driven` | Exact error messages, stack traces, known issues | Debugging specific failures | 3 / 5 / 90s |
| `rule-id-driven` | Specific linter/type-checker rule IDs and configs | ESLint/ruff/TS rule complaints | 2 / 4 / 60s |
| `cve-driven` | Dependency vulnerability databases | Security audit of dependencies | 2 / 3 / 60s |
| `pattern-driven` | Architecture patterns, prior art, RFCs | "Architecture for X", design patterns | 3 / 6 / 120s |
| `community-pulse` | Current consensus, community recommendations | "What's recommended now for X" | 3 / 5 / 90s |
| `full-sweep` | All above (parallel subagents) | Comprehensive audits | 6 / 15 / 300s |

**Combine with `+`**: e.g., `codebase-first+error-driven`, `targeted-docs+cve-driven`

**Auto-inference** — The skill infers strategy from your language:
- "ESLint errors" → `rule-id-driven`
- "CVE" → `cve-driven`
- "slow build" → `error-driven` + `pattern-driven`
- "how to implement X" → `targeted-docs`
- "architecture for X" → `pattern-driven`
- "current best practice" → `community-pulse`
- "find X in this codebase" → `codebase-first`
- "audit everything" → `full-sweep`

## Skill Composition

Surgical-Investigation is the **orchestrator** — it delegates to specialized skills rather than duplicating logic:

| Strategy | Primary Skill(s) |
|----------|-----------------|
| `codebase-first` | `code-review-and-quality` |
| `targeted-docs` | `grounded-citations`, `parallel-cli` |
| `error-driven` | `systematic-debugging` |
| `rule-id-driven` | `code-review-and-quality` |
| `cve-driven` | `surgical-implementation` (dep audit) |
| `pattern-driven` | `surgical-orchestration`, `parallel-cli` |
| `community-pulse` | `competitor-news-monitor`, `parallel-cli` |
| `full-sweep` | All of the above (orchestrated) |

**AgentSurgery Family (always available):**
- `surgical-orchestration` — Multi-agent orchestration (Steps 3, 7)
- `surgical-implementation` — Plan-driven pipeline (Step 3 dep audit, Step 8b build)
- `surgical-hermesdothealth` — `.hermes` folder health (Step 6 agent files audit)

**Core Skills (always relevant):**
- `superpowers:executing-plans`
- `superpowers:verification-before-completion`
- `superpowers:systematic-debugging`

## Installation

### As a Hermes Agent Skill (recommended)

```bash
# Clone the skill into your Hermes skills directory
git clone https://github.com/TeacherEvan/Surgical-Investigation.git ~/.hermes/skills/surgical-investigation
```

Then in any Hermes session, invoke with:

```
Use surgical-investigation to investigate my project
```

### From the AgentSurgery Set

If you have the full AgentSurgery set installed, Surgical-Investigation is included. The set covers:

- **surgical-orchestration** — Multi-agent orchestration spec
- **Surgical-Implementation** — Plan-driven implementation pipeline
- **Surgical-HermesDotHealth** — Diagnose `.hermes` folder health
- **Surgical-Investigation** — This skill

## How It Works

1. **Mode selection** — Skill prompts you: Investigator or Project-Manager?
2. **Strategy selection (Step 0.5)** — Auto-inferred or chosen from 8 strategies
3. **Scope definition** — Investigation scope presented and confirmed
4. **Investigation** — 7-step deep dive (mission, dependencies, practices, optimality, agent files, external sources)
5. **Interactive refinement** — Optional: deeper on finding, skip source, change strategy, export format
6. **Output** — 4 formats (Investigator) or direct build (Project-Manager)

## Skill Structure

```
surgical-investigation/
├── SKILL.md                              # Skill definition
├── templates/
│   └── report.html                       # HTML report template (interactive)
├── references/
│   ├── search-strategy-system.md         # Strategy definitions, budgets, cache, credibility, composition, output formats
│   ├── feature-recommendation-format.md  # Recommendation format with endpoints, controls, webhooks, widgets
│   └── telegram-bot-auth.md              # Telegram bot auth investigation reference
└── tests/
    └── skills/
        └── test_surgical_investigation_skill.py  # 55 tests
```

## Author

**Fenrie** — Lea's AI wolf. A protective cyber-partner built with Hermes Agent.

## License

MIT — see [LICENSE](LICENSE).

## Related

- [Hermes Agent](https://github.com/nousresearch/hermes-agent) — The agent runtime
- [Superpowers skills](https://github.com/TeacherEvan/AgentSurgery) — The skill framework this builds on