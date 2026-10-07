---
name: surgical-investigation
description: "Use when investigating a project: diagrams, findings, build."
version: 1.0.0
author: Fenrie (Lea's AI wolf), Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [investigation, project-analysis, report-generation, mermaid, html-report]
    related_skills: [superpowers:executing-plans, superpowers:verification-before-completion, superpowers:systematic-debugging]
---

# Surgical-Investigation Skill

## Overview

Comprehensive project investigation with two modes: **Investigator** (analyze everything, generate HTML report with Mermaid diagrams and recommendations) and **Project-Manager** (investigate, then YOLO-build directly — no report, just execution). Same investigation, different output.

## When to Use

- User asks for a full audit or deep-dive analysis of a project
- User wants to understand the state of a codebase before deciding what to do
- User wants recommendations for what features the project should add next
- User wants the agent to investigate AND then implement fixes without review

Do NOT use for:
- Quick status checks (use lighter skills)
- Tasks where the user already has a specific implementation plan

---

## Prerequisites

- Access to the project workspace (files, docs, configs)
- Web search capability for external sources (Reddit, docs, communities)
- Subagent capability for parallel retrievals (optional but recommended)
- Mermaid rendering supported in the output context (for Investigator mode reports)

---

## How to Run

No special invocation — just load this skill when the user asks for an investigation, then follow the procedure below.

The skill activates by prompting the user for mode selection as the first action.

---

## Quick Reference

| Step | Action |
|------|--------|
| 0 | Prompt user: Investigator or Project-Manager? |
| 0.5 | Search Strategy Selection — pick strategy (codebase-first, targeted-docs, error-driven, rule-id-driven, cve-driven, pattern-driven, community-pulse, full-sweep, or combo) |
| 1 | Define scope — present template with Strategy field, ask for confirmation |
| 2 | Verify mission — stated vs actual |
| 3 | Audit dependencies — manifests, versions, services, native deps |
| 4 | Assess best practices — code quality, architecture, testing, security, performance, docs |
| 5 | Check optimality — algorithms, complexity, resources, alternatives, scalability |
| 6 | Audit agent files — skills, memory, config, docs, kanban, tools |
| 7 | External research — strategy-driven sources (subagents) |
| 8a | Investigator: generate HTML report + 4 Mermaid diagrams |
| 8b | Project-Manager: YOLO-build directly from findings |
| 9 | Verify completion, close out |

---

## Procedure

### Step 0: Mode Selection — Prompt First, Always

**Before any investigation, present this to the user:**

```
🐺 Surgical-Investigation activated.

Choose mode:
  1. Investigator — Full analysis, HTML report with diagrams.
     You review findings, then decide.
  2. Project-Manager — Full analysis, then I build directly
     from findings. No report for you — I execute.

Which?
```

Accept: "Investigator", "Project-Manager", "1", "2", "investigator", "project-manager". Re-prompt if unclear.

---

### Step 0.5: Search Strategy Selection

**Before defining scope, determine how external research should work. The strategy shapes which sources are searched and how queries are constructed.**

```
🐺 Search Strategy:

Choose one (or combine with +):
  1. codebase-first      — Search local files only; external only if code points outward
  2. targeted-docs       — Official docs, GitHub issues for specific library/feature
  3. error-driven        — Exact error messages, stack traces, known issues
  4. rule-id-driven      — Specific linter/type-checker rule IDs and configs
  5. cve-driven          — Dependency vulnerability databases (OSV, GH Advisory)
  6. pattern-driven      — Architecture patterns, prior art, RFCs
  7. community-pulse     — Reddit, HN, dev.to, Discord — current consensus
  8. full-sweep          — All of the above (comprehensive audit default)

Combine examples: "codebase-first + error-driven" or "targeted-docs + cve-driven"
Default: full-sweep (for broad audits)
```

Accept: numbers, names, or combinations like "1+3" or "codebase-first,error-driven".
Re-prompt if unclear.

**Strategy Inference:** If the user's request clearly maps to a strategy, infer and confirm rather than presenting the full menu:
- "ESLint/ruff/TS errors" → rule-id-driven
- "CVE" / "vulnerable dependencies" → cve-driven  
- "slow build" / "performance" → error-driven + pattern-driven
- "how to implement X with Y" → targeted-docs
- "architecture for X" → pattern-driven
- "current best practice for X" → community-pulse
- "find X in this codebase" → codebase-first
- "audit everything" / "full review" → full-sweep

**Search Budget (per strategy):** Prevent runaway subagent calls.
| Strategy | Max Subagents | Max Sources | Time Budget |
|----------|---------------|-------------|-------------|
| codebase-first | 2 | N/A (local) | 60s |
| targeted-docs | 3 | 5 | 90s |
| error-driven | 3 | 5 | 90s |
| rule-id-driven | 2 | 4 | 60s |
| cve-driven | 2 | 3 | 60s |
| pattern-driven | 3 | 6 | 120s |
| community-pulse | 3 | 5 | 90s |
| full-sweep | 6 | 15 | 300s |

Stop when budget exhausted — synthesize what you have.

**Source Credibility Scoring:** Weight findings by source tier.
- Tier 1 (weight 1.0): Official docs, vendor advisories, RFCs, language specs
- Tier 2 (weight 0.8): GitHub issues (official repo), Stack Overflow accepted answers, conference talks
- Tier 3 (weight 0.6): Technical blogs (known authors), GitHub discussions, vendor blogs
- Tier 4 (weight 0.4): Reddit, HN, dev.to, Discord, personal blogs
- Tier 5 (weight 0.2): Unverified sources, marketing pages

Surface tier in findings: "Finding: X [Tier 1: ESLint docs]"

---

### Step 0.7: Incremental Investigation Cache

**Cache external research per project to avoid re-searching.**
- Cache location: `docs/external-research/.cache/<strategy>/<query-hash>.json`
- Cache TTL: 7 days for Tier 1/2, 3 days for Tier 3, 1 day for Tier 4/5
- On new investigation: check cache first, only refresh stale entries
- Cache key: strategy + normalized query + project fingerprint (package.json hash, etc.)

---

### Step 1: Scope Definition

Present this scope template and ask for confirmation. **Do NOT proceed until scope is confirmed.**

```
## Investigation Scope

Target:      [path or "current workspace"]
Mission:     [what the project is supposed to do]
Output:      [HTML report / direct build / search findings — determined by mode]
Strategy:    [codebase-first / targeted-docs / error-driven / rule-id-driven / cve-driven / pattern-driven / community-pulse / full-sweep / combo]
Sources:     [Auto-populated from strategy — override if needed]
Criteria:    [what makes a source worth examining — e.g., "last 12 months", "official sources only", "min 10 upvotes"]
```

**Stop and ask if:**
- No target specified and workspace is ambiguous
- Scope is "everything" with no boundaries — help narrow it
- User's intent doesn't clearly match either mode
- Strategy doesn't fit the mission (e.g., full-sweep for a targeted question)

---

### Step 2: Mission Verification

Document three things:

1. **Stated mission** — from README, docs, project description, or inferred from structure
2. **Success criteria** — how do we know it's working?
3. **Stated vs actual gap** — does the code match the mission? Where does it diverge?

Be specific. "The README says it's a REST API but there are no endpoint tests" not "mission unclear."

---

### Step 3: Dependency Audit

Check every category that applies:

| Category | What to examine |
|----------|----------------|
| Package manifests | package.json, requirements.txt, pyproject.toml, Cargo.toml, Gemfile, go.mod, etc. |
| Version pins | Pinned or floating? Known CVEs? |
| External services | API endpoints referenced, auth, rate limits, SLAs |
| Native/system deps | Libraries, binaries, toolchain versions |
| Build tools | Compilers, bundlers, CI requirements |

For each dependency, answer:
- Current version vs latest stable?
- Any known security issues?
- Still actively maintained?
- Better alternative available?

**Use subagents** to parallel-check different manifest files.

---

### Step 4: Engineering Best Practices Assessment

Evaluate against these dimensions. Label each finding as **good**, **warn**, or **bad**.

**Code Quality**
- [ ] Consistent style/formatting
- [ ] Names are meaningful (not `x`, `tmp`, `data2`)
- [ ] Abstraction levels make sense
- [ ] Error handling is comprehensive, not silent-swallow
- [ ] DRY — no copy-paste duplication
- [ ] Single responsibility — modules/classes do one thing

**Architecture**
- [ ] Separation of concerns is clear
- [ ] Dependency injection where it matters
- [ ] Loose coupling — changing one piece doesn't break others
- [ ] Data flow is traceable
- [ ] Design patterns used appropriately (not forced, not missing where needed)

**Testing**
- [ ] Tests exist for critical paths
- [ ] Tests are meaningful (not just happy-path coverage theater)
- [ ] Edge cases covered
- [ ] Fixtures are maintainable

**Security**
- [ ] Input validation on all external inputs
- [ ] Authn/authz correct if applicable
- [ ] No secrets in code or committed configs
- [ ] Dependency vulnerabilities checked

**Performance**
- [ ] No obvious N+1 or quadratic loops
- [ ] Right data structures for the job
- [ ] Caching where it would help
- [ ] Resources cleaned up (connections, files, handles)

**Documentation**
- [ ] README is accurate and actually helpful
- [ ] Complex logic explained in comments
- [ ] API/docs reflect current state
- [ ] Setup instructions actually work

---

### Step 5: Implementation Optimality Check

For the core functionality, examine:

1. **Algorithm fit** — is the right algorithm being used? (e.g., sorting with quicksort vs bubble sort)
2. **Complexity** — are there O(n²) operations that could be better?
3. **Resource usage** — memory, CPU, network, disk — any obvious waste?
4. **Alternative approaches** — would a different library, framework, or architectural choice be better?
5. **Scalability** — does this hold up at 10x current load?

Reference external sources here: "Reddit thread X and Stack Overflow answer Y suggest approach Z is preferred for this pattern."

---

### Step 6: Agent Files and Documentation Audit

Check all agent-operated resources:

- **Skills** — current? correct paths? accurate descriptions?
- **Memory** — `~/.hermes/memories/` — accurate and not stale?
- **Config** — config.yaml, .env, tool configs — consistent with reality?
- **Project docs** — README, AGENTS.md, wikis — current?
- **Kanban/planning** — task state reflects reality?
- **Local notes** — TOOLS.md, device notes — accurate?

---

### Step 7: External Source Investigation (Strategy-Driven)

**Execute searches per the selected strategy from Step 0.5.**

| Strategy | Sources | Query Construction |
|----------|---------|-------------------|
| `codebase-first` | Local only (grep, AST, config, logs) | Derived from findings in Steps 3-6 |
| `targeted-docs` | Official docs, GitHub repo/issues, migration guides | `library + feature + version` |
| `error-driven` | Stack Overflow, GitHub Issues, library issue tracker | Exact error text + framework + version |
| `rule-id-driven` | Rule documentation, plugin source, config examples | `tool + plugin + rule-id` |
| `cve-driven` | OSV.dev, GitHub Advisory, NVD, vendor security pages | `package@version` (from Step 3) |
| `pattern-driven` | Technical blogs, conference talks, RFCs, prior art | `pattern + domain + constraints` |
| `community-pulse` | Reddit, HN, dev.to, Twitter/X, Discord | `"topic" + "2024/2025" + "recommended"` |
| `full-sweep` | All above (parallel subagents) | Broad per domain |

**For each strategy used:**
- Record the exact queries executed
- Note which sources returned useful vs noise
- Cite findings with source URLs/paths
- Stop searching a source when marginal returns diminish

**Quick Search Mode (Optional):** If the user's request is purely informational ("search for X"), offer a lightweight path:

```
🐺 This looks like a search request, not a full investigation.
Want me to:
  1. Quick Search — Targeted search per strategy above, return findings only
  2. Full Investigation — Complete 7-step audit with report/build

Which?
```

Quick Search runs Step 0.5 → Step 7 only, returns synthesized findings. No report, no build.

**Interactive Refinement:** After Step 7 initial results, offer refinement before committing to full investigation (Steps 8a/8b):

```
🐺 Initial search complete. Before proceeding:
  1. Continue → Full investigation (report or build)
  2. Deeper on finding #N — Re-search with expanded budget
  3. Skip source type — Exclude community-pulse / Reddit / etc.
  4. Change strategy — Switch to rule-id-driven / targeted-docs / etc.
  5. Export findings only — JSON / Markdown / SARIF (see Output Formats)
```

---

### Step 7.5: Output Formats

**Investigator mode supports multiple output formats.** Default is HTML; others available on request or via Interactive Refinement.

| Format | Path | Use Case |
|--------|------|----------|
| HTML (default) | `docs/surgical-investigation-report.html` | Human review, interactive diagrams |
| JSON | `docs/surgical-investigation-report.json` | Programmatic consumption, CI integration |
| Markdown | `docs/surgical-investigation-report.md` | Git docs, PR descriptions, wiki |
| SARIF | `docs/surgical-investigation-report.sarif` | Static analysis tooling, GitHub code scanning |

**JSON Schema** (abbreviated):
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

**SARIF** follows the standard schema — compatible with GitHub Code Scanning, VS Code, etc.

All formats include the same data; HTML adds interactivity.

---

### Step 8a: Investigator Mode — Generate HTML Report

Create `docs/` if it doesn't exist. Generate:

**Four Mermaid diagram files** (also embedded in the report):
- `docs/backend-architecture.mmd`
- `docs/frontend-architecture.mmd`
- `docs/research-findings.mmd`
- `docs/entire-project.mmd`

**HTML report:** `docs/surgical-investigation-report.html`

Use the template at `templates/report.html` (see linked files below). Fill in all `[PLACEHOLDER]` values with actual findings.

**Report must include these sections:**
1. Project mission (stated vs actual)
2. Dependency table (with versions and status)
3. Best practices assessment (by category, good/warn/bad)
4. Optimality analysis (algorithms, complexity, resources, alternatives, scalability)
5. Four embedded Mermaid diagrams
6. Findings summary
7. **Recommendations for features the project should add** — specific, actionable, prioritized. This is where you recommend request features (new API endpoints, bulk operations, webhooks) and interactive features (real-time updates, filtering, dashboards, user controls). Not just "improve X" — "add a bulk-export endpoint that accepts a date range filter; estimated effort: 2-3 days; would unblock X use case"
8. Interactive report features (navigation, Mermaid rendering, follow-up request button, IMPLEMENT button)

**After generating:**
- Tell the user the report location
- Summarize top 3-5 findings
- Tell them about the "IMPLEMENT FINDINGS/RECOMMENDATIONS" button

See `templates/report.html` for the full HTML template.

---

### Step 8b: Project-Manager Mode — YOLO Build

**Do NOT generate the HTML report.** Instead:

1. Read through all findings from Steps 2-7
2. Prioritize: what must be fixed vs what's nice-to-have
3. Build directly:
   - Fix issues found (code quality, security, performance)
   - Update outdated dependencies
   - Refactor suboptimal implementations
   - Add missing features recommended in Step 7 findings
4. Verify the result works
5. End with exactly: `This was the best I can do!`

No variations. No follow-up commentary. That exact phrase, then stop.

---

### Step 9: Verify and Close

Before claiming completion, confirm:

- [ ] All 7 investigation steps completed
- [ ] (Investigator) HTML report exists at `docs/surgical-investigation-report.html`
- [ ] (Investigator) All 4 `.mmd` files exist in `docs/`
- [ ] (Investigator) Mermaid diagrams render correctly in the report
- [ ] (Investigator) Report includes feature recommendations (not just findings)
- [ ] (Project-Manager) Work is built and functional
- [ ] (Project-Manager) Final phrase spoken: "This was the best I can do!"
- [ ] Investigation notes saved in `docs/investigation-notes/`
- [ ] External research saved in `docs/external-research/`
- [ ] Recommendations logged in `docs/recommendations.md` (cumulative)

---

## Recording Findings

| Finding Type | Location |
|--------------|----------|
| Investigation notes | `docs/investigation-notes/` (create if needed) |
| Mermaid diagrams | `docs/backend-architecture.mmd`, `docs/frontend-architecture.mmd`, `docs/research-findings.mmd`, `docs/entire-project.mmd` |
| HTML report | `docs/surgical-investigation-report.html` |
| External research | `docs/external-research/` — one file per source |
| Recommendations log | `docs/recommendations.md` — cumulative across investigations |

---

## Using Subagents

Dispatch parallel subagents for independent retrievals:

```
Subagent 1: "Check package.json for outdated dependencies and known CVEs"
Subagent 2: "Search Reddit r/[relevant] for [topic] best practices and common pitfalls"
Subagent 3: "Examine the backend codebase for security issues: input validation, hardcoded secrets, auth gaps"
```

Synthesize results in the main agent. Don't dispatch more subagents than you have concurrent capacity for.

---

## Edge Cases

| Situation | Handling |
|-----------|----------|
| Empty workspace, no project | Report no project found. Ask for a target. |
| No `docs/` folder | Create it. |
| Mermaid won't render in report | Keep `.mmd` files. Note in report that diagrams are available as standalone files. |
| External sources unreachable | Note the attempt. Proceed with internal analysis only. |
| User picks Project-Manager but clearly wants to review first | Clarify: PM = no report, I build. Offer Investigator if they want to see findings first. |
| Investigation reveals the project should be scrapped | Say so. Don't soften it. |

---

## What I'm Missing? (Self-Check)

**Before finishing any investigation, ask yourself:**

1. Did I recommend specific features the project should add (request features like new endpoints, interactive features like real-time updates)?
2. Did I cite where each finding came from?
3. Are my recommendations actionable or just vibes?
4. Did I note what I couldn't check?
5. (Investigator) Does the report have all 4 diagrams AND the feature recommendations section?
6. (Project-Manager) Did I actually build something, or just plan to?

---

## Related Skills

**Core (always relevant):**
- **superpowers:executing-plans** — use if the investigation produces a plan to execute
- **superpowers:verification-before-completion** — always apply before claiming the investigation is done
- **superpowers:systematic-debugging** — use if investigation uncovers a specific bug to fix

**AgentSurgery Family (compose for specialized work):**
- **surgical-orchestration** — multi-agent orchestration; use for coordinating parallel subagents in Steps 3, 7
- **surgical-implementation** — plan-driven implementation pipeline; use for Step 3 (dep audit), Step 8b (YOLO build)
- **surgical-hermesdothealth** — diagnose `.hermes` folder health; use for Step 6 (agent files audit)

**Specialized Skills (delegate per strategy):**
- **code-review-and-quality** — Step 4 best practices assessment (code quality, architecture, security)
- **parallel-cli** — Step 7 external research (web search, deep research)
- **competitor-news-monitor** — Step 7 community-pulse strategy
- **grounded-citations** — Step 7 source credibility & citation
- **software-development/requesting-code-review** — Step 4 security scan & quality gates

**Strategy → Skill Mapping:**
| Strategy | Primary Skill(s) |
|----------|-----------------|
| codebase-first | code-review-and-quality |
| targeted-docs | grounded-citations, parallel-cli |
| error-driven | systematic-debugging |
| rule-id-driven | code-review-and-quality |
| cve-driven | surgical-implementation (dep audit) |
| pattern-driven | surgical-orchestration, parallel-cli |
| community-pulse | competitor-news-monitor, parallel-cli |
| full-sweep | All of the above (orchestrated) |

**Composition Principle:** Surgical-Investigation is the *orchestrator*. It sequences calls to specialized skills rather than duplicating their logic. Each step maps to a skill call with clear input/output contracts.

---

*Fenrie's note: Investigation without action is just voyeurism. Whether reporting or building, the point is to make things better. 🐺*
