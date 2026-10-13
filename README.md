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

## Keeping Installs in Sync

This repo is the **canonical source**. Installs are copies, and copies drift — the
checksum-verified reality after v1.1.0 was that three installs still sat on the old
version while the repo had moved on. Don't fix that by hand:

```bash
./scripts/sync-skill.sh check    # show what differs, change nothing (exit 1 if stale)
./scripts/sync-skill.sh sync     # bring every install up to date
./scripts/sync-skill.sh verify   # byte-compare each install, change nothing
```

Default targets (relative to `$HOME`), override with `SKILL_TARGETS=a:b:c`:

| Target | Agent |
|---|---|
| `.hermes/skills/surgical-investigation` | Hermes (primary) |
| `.config/opencode/skills/surgical-investigation` | OpenCode |
| `.gemini/skills/surgical-investigation` | Gemini CLI |
| `.gemini/surgical/surgical-investigation` | Gemini CLI (bundle) |
| `.gemini/antigravity-cli/skills/surgical-investigation` | Antigravity CLI |

Mirrored: `SKILL.md`, `README.md`, `templates/`, `references/`, `docs/`.
Never mirrored or deleted: `.git/`, `.github/`, `tests/`, `scripts/`, and anything
matching `_archive*` — past investigation outputs stay put and never propagate.

### Verify before pushing

`check` and `verify` use different mechanisms on purpose (rsync dry-run vs
`diff -r`/`cmp`), so a passing `verify` is evidence rather than a tool agreeing
with itself. Neither one writes anything.

CI lives in `.github/workflows/skill-ci.yml`. Replay it locally instead of guessing
whether it will pass — this reads the workflow itself, so there is no second copy
of the checks to drift:

```bash
python3 -m venv .venv && .venv/bin/pip install pytest pyyaml
.venv/bin/python scripts/run-ci-locally.py   # exit 0 = every step would pass
```

## How It Works

1. **Mode selection** — Skill prompts you: Investigator or Project-Manager?
2. **Strategy selection (Step 0.5)** — Auto-inferred or chosen from 8 strategies
3. **Scope definition** — Investigation scope presented and confirmed
4. **Investigation** — 7-step deep dive (mission, dependencies, practices, optimality, agent files, external sources)
5. **Interactive refinement** — Optional: deeper on finding, skip source, change strategy, export format
6. **Output** — 4 formats (Investigator) or direct build (Project-Manager)

7. **Escalation protocol** — When challenged with "Is this the best you can do?", activates 4-pillar escalation: subagent depth, multi-format output expansion, Tier 1-2 external verification, and actionable endpoints/controls.

## "Best You Can Do" Escalation Protocol

When asked "Is this the best you can do?", the agent executes a four-pillar escalation rather than repeating findings:

1. **Subagent Depth**: Spawns parallel subagents across multiple search strategies and sources.
2. **Multi-Format Output Expansion**: Emits all 4 report formats (`.html`, `.json`, `.md`, `.sarif`) generated from dedicated templates in `templates/`.
3. **External Verification**: Cross-references findings against Tier 1-2 authoritative sources (official documentation, vendor advisories, RFC specs).
4. **Actionable Recommendations with Concrete Endpoints & Controls**: Replaces vague suggestions with explicit REST/GraphQL endpoints, CLI syntax, webhook event names, and interactive UI widget specs.

## Skill Structure

```
surgical-investigation/
├── SKILL.md                              # Skill definition and procedure rules
├── templates/
│   ├── report.html                       # HTML report template (interactive)
│   ├── report.json                       # JSON report template (machine-readable)
│   ├── report.md                         # Markdown report template (documentation/PRs)
│   └── report.sarif                      # SARIF 2.1.0 report template (code scanning)
├── references/
│   ├── search-strategy-system.md         # Strategy definitions, budgets, cache, credibility, composition, output schemas
│   ├── feature-recommendation-format.md  # Recommendation format with endpoints, controls, webhooks, widgets
│   ├── external-service-auth.md          # External service authorization layers & debug rules
│   ├── mermaid-best-practices.md         # Diagram size limits, naming, subgraphs, color coding
│   ├── sarif-schema.md                   # SARIF 2.1.0 schema mapping and rules
│   └── skill-authoring-standards.md      # Hermes skill authoring guidelines and checklist
├── docs/                                 # Investigation reports and research notes
│   ├── surgical-investigation-report.html # Generated report (interactive, default)
│   ├── surgical-investigation-report.json # Generated report (machine-readable)
│   ├── surgical-investigation-report.md   # Generated report (documentation/PRs)
│   ├── surgical-investigation-report.sarif # Generated report (code scanning)
│   ├── recommendations.md                # Actionable recommendations with endpoints
│   ├── research-findings.mmd             # Mermaid: external research map
│   ├── backend-architecture.mmd          # Mermaid: backend architecture
│   ├── frontend-architecture.mmd         # Mermaid: frontend architecture
│   ├── entire-project.mmd                # Mermaid: whole-project view
│   ├── external-research/                # Tier 1-2 source notes
│   └── investigation-notes/              # Meta-investigation run notes
├── scripts/
│   └── sync-skill.sh                     # Mirror assets into local agent installs
└── tests/
    └── skills/
        └── test_surgical_investigation_skill.py  # Unit and integration test suite
```

## Author

**Fenrie** — Lea's AI wolf. A protective cyber-partner built with Hermes Agent.

## License

MIT — see [LICENSE](LICENSE).

## Related

- [Hermes Agent](https://github.com/nousresearch/hermes-agent) — The agent runtime
- [Superpowers skills](https://github.com/TeacherEvan/AgentSurgery) — The skill framework this builds on