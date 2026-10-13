# Cumulative Recommendations Log: Surgical-Investigation

Actionable recommendations produced across investigations. Per `references/feature-recommendation-format.md`, each recommendation includes concrete REST/GraphQL endpoints, CLI arguments, webhook event names, or UI control specifications.

---

## REC-001: Automated SARIF Report Upload via GitHub Action

- **Priority:** High
- **Category:** CI/CD Integration & Static Analysis
- **Why:** Enables GitHub Code Scanning to automatically display investigation findings, security vulnerabilities, and code quality suggestions directly on PR lines.
- **What:** Add a dedicated reusable GitHub Action workflow (`.github/workflows/upload-sarif.yml`) that runs `surgical-investigation --mode investigator --format sarif` and uploads `docs/surgical-investigation-report.sarif` via `github/codeql-action/upload-sarif@v3`.
- **Endpoint / CLI:** `surgical-investigation run --mode investigator --format sarif --out docs/`
- **Interactive Control / UI:** GitHub Code Scanning security tab with inline PR annotations and status check badges.
- **Estimated Effort:** 1 day
- **Source:** [Tier 1: GitHub Code Scanning Documentation & OASIS SARIF 2.1.0 Specification]

---

## REC-002: CLI Diagnostic Pre-flight Subcommand (`agy-investigate`)

- **Priority:** Medium
- **Category:** Interactive Control & Developer Experience
- **Why:** Allows developers to execute a quick audit directly from terminal without manually crafting LLM prompts or starting interactive chat.
- **What:** Add a lightweight CLI runner script in `scripts/investigate.py` that supports flags for mode, search strategy, and format selection.
- **Endpoint / CLI:** `python3 -m surgical_investigation --target . --mode investigator --strategy full-sweep --formats html,sarif,json`
- **Interactive Control / UI:** Terminal progress bar with interactive strategy selection prompt (`gum` or `curses`-style multi-select).
- **Estimated Effort:** 2 days
- **Source:** [Tier 2: Agent CLI Design Patterns & Hermes Tool Architecture]

---

## REC-003: Real-Time Cache Invalidation Webhook & TTL Management

- **Priority:** Medium
- **Category:** Caching & Performance Optimality
- **Why:** Avoids re-running expensive external queries while ensuring stale research entries (>7 days for Tier 1/2, >3 days for Tier 3, >1 day for Tier 4/5) are evicted when upstream repositories receive new commits.
- **What:** Add a cache manager module that computes commit tree hashes (`git rev-parse HEAD`) and prunes expired query caches in `docs/external-research/.cache/`.
- **Endpoint / CLI:** `POST /api/v1/cache/invalidate` or CLI command: `surgical-investigation cache prune --max-age 7d`
- **Interactive Control / UI:** Toggle switch in HTML report to "Force Refresh External Research Cache".
- **Estimated Effort:** 1-2 days
- **Source:** [Tier 1: Incremental Investigation Cache Specification in SKILL.md Step 0.7]

---

## REC-004: Interactive Diagram Pan/Zoom and Fullscreen Toggle in HTML Report

- **Priority:** Low
- **Category:** User Interface & Visualization
- **Why:** Complex architectures with >20 nodes can become constrained in default card wrappers.
- **What:** Add SVG pan-zoom library (`svg-pan-zoom.js`) to `templates/report.html` allowing click-and-drag panning, scroll zooming, and fullscreen diagram modals.
- **Endpoint / CLI:** Client-side interaction (`openDiagramFullscreen('backend')`)
- **Interactive Control / UI:** Floating action buttons over each diagram card (`[ + ]`, `[ - ]`, `[ ⛶ Fullscreen ]`).
- **Estimated Effort:** 1 day
- **Source:** [Tier 2: Mermaid Best Practices & UI Visualization Standards]
