# Search Strategy System — Reference for Surgical-Investigation

Consolidated decision tables and rules for Step 0.5 (Strategy Selection), Step 0.7 (Cache), and Step 7 (External Research). Load this reference when the investigation requires strategy-driven search behavior.

---

## Strategy Definitions

| Strategy | Description | Primary Sources | Query Construction |
|----------|-------------|-----------------|-------------------|
| `codebase-first` | Search local files only; external only if code points outward | Local (grep, AST, config, logs) | Derived from findings in Steps 3-6 |
| `targeted-docs` | Official docs, GitHub issues for specific library/feature | Official docs, GitHub repo/issues, migration guides | `library + feature + version` |
| `error-driven` | Exact error messages, stack traces, known issues | Stack Overflow, GitHub Issues, library issue tracker | Exact error text + framework + version |
| `rule-id-driven` | Specific linter/type-checker rule IDs and configs | Rule documentation, plugin source, config examples | `tool + plugin + rule-id` |
| `cve-driven` | Dependency vulnerability databases | OSV.dev, GitHub Advisory, NVD, vendor security pages | `package@version` (from Step 3) |
| `pattern-driven` | Architecture patterns, prior art, RFCs | Technical blogs, conference talks, RFCs, prior art | `pattern + domain + constraints` |
| `community-pulse` | Current consensus, community recommendations | Reddit, HN, dev.to, Twitter/X, Discord | `"topic" + "2024/2025" + "recommended"` |
| `full-sweep` | All above (parallel subagents) | All sources | Broad per domain |

**Combine with `+`**: e.g., `codebase-first+error-driven`, `targeted-docs+cve-driven`
**Default**: `full-sweep` (comprehensive audits)

---

## Strategy Inference Rules

Infer strategy from user's natural language — confirm before proceeding.

| User Language Pattern | Inferred Strategy |
|-----------------------|-------------------|
| "ESLint/ruff/TS errors", "lint errors", "rule complaints" | `rule-id-driven` |
| "CVE", "vulnerable dependencies", "security audit deps" | `cve-driven` |
| "slow build", "performance", "bottleneck", "timeout" | `error-driven` + `pattern-driven` |
| "how to implement X with Y", "using library Z for X" | `targeted-docs` |
| "architecture for X", "design pattern for X", "best structure" | `pattern-driven` |
| "current best practice for X", "what's recommended now" | `community-pulse` |
| "find X in this codebase", "where is X used" | `codebase-first` |
| "audit everything", "full review", "comprehensive analysis" | `full-sweep` |

---

## Search Budgets (Per Strategy)

Prevent runaway subagent calls. Stop when budget exhausted — synthesize what you have.

| Strategy | Max Subagents | Max Sources | Time Budget |
|----------|---------------|-------------|-------------|
| `codebase-first` | 2 | N/A (local) | 60s |
| `targeted-docs` | 3 | 5 | 90s |
| `error-driven` | 3 | 5 | 90s |
| `rule-id-driven` | 2 | 4 | 60s |
| `cve-driven` | 2 | 3 | 60s |
| `pattern-driven` | 3 | 6 | 120s |
| `community-pulse` | 3 | 5 | 90s |
| `full-sweep` | 6 | 15 | 300s |

---

## Source Credibility Tiers

Weight findings by tier. Surface tier in output: `"Finding: X [Tier 1: ESLint docs]"`

| Tier | Weight | Sources |
|------|--------|---------|
| 1 | 1.0 | Official docs, vendor advisories, RFCs, language specs |
| 2 | 0.8 | GitHub issues (official repo), Stack Overflow accepted answers, conference talks |
| 3 | 0.6 | Technical blogs (known authors), GitHub discussions, vendor blogs |
| 4 | 0.4 | Reddit, HN, dev.to, Discord, personal blogs |
| 5 | 0.2 | Unverified sources, marketing pages |

---

## Incremental Investigation Cache (Step 0.7)

| Parameter | Value |
|-----------|-------|
| Cache location | `docs/external-research/.cache/<strategy>/<query-hash>.json` |
| Cache key | strategy + normalized query + project fingerprint (package.json hash, etc.) |
| TTL Tier 1/2 | 7 days |
| TTL Tier 3 | 3 days |
| TTL Tier 4/5 | 1 day |
| On new investigation | Check cache first, only refresh stale entries |

---

## Strategy → Skill Mapping (Composition Principle)

Surgical-Investigation orchestrates; delegates to specialized skills.

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

**AgentSurgery Family (always available for composition):**
- `surgical-orchestration` — multi-agent orchestration (Steps 3, 7)
- `surgical-implementation` — plan-driven pipeline (Step 3 dep audit, Step 8b build)
- `surgical-hermesdothealth` — `.hermes` folder health (Step 6 agent files audit)

**Core Skills (always relevant):**
- `superpowers:executing-plans`
- `superpowers:verification-before-completion`
- `superpowers:systematic-debugging`

---

## Output Format Specifications (Step 7.5)

### JSON Schema
```json
{
  "project": "string",
  "timestamp": "ISO8601",
  "mode": "investigator|project-manager",
  "strategy": "string",
  "mission": { "stated": "", "actual": "", "gap": "" },
  "dependencies": [{ "name": "", "version": "", "latest": "", "status": "", "tier": 0 }],
  "practices": { "codeQuality": [], "architecture": [], "testing": [], "security": [], "performance": [], "documentation": [] },
  "optimality": { "algorithm": "", "complexity": "", "resources": "", "alternatives": [], "scalability": "" },
  "agentFiles": [],
  "externalResearch": [{ "strategy": "", "query": "", "source": "", "tier": 0, "finding": "", "url": "" }],
  "recommendations": [{ "priority": "high|medium|low", "title": "", "why": "", "what": "", "effort": "", "source": "" }],
  "diagrams": { "backend": "", "frontend": "", "research": "", "entire": "" }
}
```

### SARIF
Follows standard SARIF 2.1.0 schema — compatible with GitHub Code Scanning, VS Code, and static analysis tooling.

### Markdown
Human-readable summary with same data structure as JSON, rendered as sections.

### HTML (Default)
Interactive report with Mermaid diagrams, sticky navigation, follow-up request modal, IMPLEMENT button.

All formats contain the same data; HTML adds interactivity.

---

## Quick Search Mode Decision

Trigger when user request is purely informational ("search for X").

```
🐺 This looks like a search request, not a full investigation.
Want me to:
  1. Quick Search — Targeted search per strategy above, return findings only
  2. Full Investigation — Complete 7-step audit with report/build
```

Quick Search runs Step 0.5 → Step 7 only. Returns synthesized findings. No report, no build.

---

## Interactive Refinement Options

After Step 7 initial results, before committing to Steps 8a/8b:

```
🐺 Initial search complete. Before proceeding:
  1. Continue → Full investigation (report or build)
  2. Deeper on finding #N — Re-search with expanded budget
  3. Skip source type — Exclude community-pulse / Reddit / etc.
  4. Change strategy — Switch to rule-id-driven / targeted-docs / etc.
  5. Export findings only — JSON / Markdown / SARIF
```
