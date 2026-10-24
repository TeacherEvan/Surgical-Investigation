# Modern Standards Baseline — Reference

Read this before Step 3 and again before Step 8a. It maps each concept in the procedure to the
current standard or tool, so findings cite a version instead of a memory. Every row below was
checked against a primary source; the URL is the citation, and the tier follows
`references/search-strategy-system.md` (Tier 1 = spec/vendor, Tier 2 = official repo/registry).

> **Rule:** if a finding touches a standard in this table, name the version in the finding.
> "CVSS 9.8" is not a finding; "CVSS v4.0 9.8, EPSS 0.71, in KEV" is.

## 1. Vulnerability & dependency evidence

| Concept | Current standard (verified) | What to change in the procedure |
|---|---|---|
| Severity | **CVSS v4.0** — Base / Threat / Environmental / Supplemental metric groups | Record the **vector string**, not just the score. CVSS is severity, not risk; do not rank by it alone. [Tier 1: FIRST] |
| Exploit likelihood | **EPSS** — daily 0–1 probability of exploitation within 30 days, plus percentile | Pair every CVE with its EPSS score + percentile. Treat it as a daily-changing signal. [Tier 1: first.org/epss] |
| Confirmed exploitation | **CISA KEV** catalogue | Any KEV hit is an immediate P0 regardless of CVSS. KEV covers ~0.5% of CVEs — absence is not safety. [Tier 1: cisa.gov/known-exploited-vulnerabilities-catalog] |
| Reachability | Call-graph / call-analysis reachability (e.g. `osv-scanner --call-analysis`, commercial equivalents) | Demote findings with no reachable path from an untrusted input; say "not reachable" explicitly rather than dropping them. [Tier 2: osv-scanner] |
| SBOM | **CycloneDX 1.6/1.7** or **SPDX 3.0.1** | If the target ships an SBOM, scan the SBOM; if not, generate one (`osv-scanner --sbom`, `syft`) and attach it as evidence. [Tier 1: cyclonedx.org, spdx.dev; Tier 2: BSI TR-03183-2 v2.1.0] |
| Scanner | **osv-scanner v2.7+** (OSV database, lockfile-native, license scan, CycloneDX output) | Prefer lockfile scan over manifest scan — floating ranges hide the installed version. [Tier 2: github.com/google/osv-scanner/releases] |
| Supply chain | **OpenSSF Scorecard**, SLSA provenance/attestations | For a dependency that is critical and unmaintained, report its Scorecard posture rather than only "no CVEs". [Tier 2] |

**Prioritisation order to state in the report:** KEV → reachable + EPSS ≥ 0.1 → CVSS ≥ 9.0 unreachable
→ everything else. Never present a flat CVSS-sorted list.

## 2. Code & architecture evidence

| Concept | Current practice | What to change |
|---|---|---|
| Structural search | AST-aware search (`ast-grep`, tree-sitter, Semgrep, CodeQL) | `grep` cannot prove absence. If a finding is "no input validation anywhere", it must come from an AST/rule query, not a text search. |
| Contract integrity | **JSON Schema 2020-12** (`$schema`, `unevaluatedProperties`) | Validate the report JSON against a shipped schema before claiming the pipeline output is machine-readable. |
| API contracts | OpenAPI 3.1 (JSON Schema 2020-12 aligned) | When recommending an endpoint, give the OpenAPI fragment, not prose. |
| Observability | **OpenTelemetry** semantic conventions | When recommending instrumentation, name the signal (trace/metric/log) and the semconv attribute. |

## 3. Accessibility & interface (Step 4 "Documentation/UX" and any HTML artefact)

| Concept | Current standard | What to change |
|---|---|---|
| Conformance target | **WCAG 2.2** (W3C Recommendation, 5 Oct 2023) | Audit against 2.2, not 2.1. Report which SC fails, by number. |
| Target size | **2.5.8 Target Size (Minimum), AA — 24×24 CSS px** (or the spacing exception) | Any report/dashboard control smaller than 24 px without spacing is a finding. |
| Focus visibility | **2.4.11 Focus Not Obscured (AA)**, **2.4.13 Focus Appearance (AAA)** | Sticky headers/footers hiding the focused control are 2.4.11 failures. |
| Auth | **3.3.8 Accessible Authentication (Minimum, AA)** | No cognitive-function test as the only auth path. |
| Colour | APCA or WCAG 2.x contrast computed on the **composited** background | Report the measured ratio, not the token's nominal value. |
| Motion | `prefers-reduced-motion` + `prefers-contrast` + `forced-colors` | Three media queries, not one. |

## 4. Diagrams (Step 8a)

| Concept | Current practice | What to change |
|---|---|---|
| Renderer | **Mermaid 11.x** (v11.0.0 released 2024-08-23; `architecture-beta` from 11.1.0) | Pin `mermaid@11` in the template. v10 syntax is a subset; v11 adds the types below. |
| Architecture diagram | **`architecture-beta`** — `group`/`service`/`edge`/`junction`, cloud + CI/CD oriented | Use it for `backend-architecture.mmd`; keep `graph`/`flowchart` for process flows. |
| Accessibility | **`accTitle:` + `accDescr:`** on every diagram (single-line or `{ }` block) | Mermaid emits `<title>`/`<desc>` + `aria-labelledby`/`aria-describedby` from these. A diagram without them is an a11y defect in the report itself. |
| Layout | ELK layout (`@mermaid-js/layout-elk`) for dense graphs | Use when a `graph` exceeds ~25 nodes. |
| Limits | ≤ 50 nodes, ≤ 4 subgraph levels | Unchanged — but say which diagram was split and why. |

## 5. Agent-facing context (Step 6)

| Concept | Current standard | What to change |
|---|---|---|
| Project instructions | **AGENTS.md** — open format, 60k+ repos, stewarded by the Agentic AI Foundation (Linux Foundation, Dec 2025) | Audit for `AGENTS.md` at the root and nested per-package; nearest file wins. A repo with agent tooling and no `AGENTS.md` is a Step 6 finding. |
| Tool integration | **MCP**, revision **2025-11-25** (previous stable 2025-06-18) | When recommending a data source, prefer "MCP server if one exists, REST/JSON API otherwise, scrape last". |
| Doc discovery | `llms.txt` / `llms-full.txt` | Check for it before scraping a docs site. |

## 6. Evidence & delivery

| Concept | Current practice | What to change |
|---|---|---|
| Report interchange | **SARIF 2.1.0 + Errata 01** (published OASIS standard) | Keep 2.1.0. **SARIF 2.2 is CSD01 (09 Oct 2026), public comment only** — do not emit 2.2 yet. [Tier 1: docs.oasis-open.org/sarif; oasis-open.org 2026-10-20 announcement] |
| Code scanning | GitHub `upload-sarif` (CodeQL action v3) accepts 2.1.0 | Give the workflow step in the recommendation when CI integration is proposed. |
| Decisions | **ADR** (Nygard format: Title / Status / Context / Decision / Consequences) in `docs/adr/NNNN-*.md` | Every high-priority recommendation becomes an ADR stub with the alternatives considered. |
| Cache | **RFC 9111** conditional requests (`ETag`/`If-None-Match`, `Last-Modified`) | Keep the TTL tiers, but revalidate with the origin instead of blindly re-fetching after expiry. Content-address the cache key (`sha256(strategy + normalized_query + project_fingerprint)`). |
| Provenance | Retrieval timestamp + content hash + URL per external source | Store in `docs/external-research/` so a later run can prove what changed. |

## Citations

- Mermaid accessibility (`accTitle`/`accDescr`): https://mermaid.ai/open-source/config/accessibility.html — Tier 1
- Mermaid `architecture-beta` (v11.1.0+): https://mermaid.ai/open-source/syntax/architecture.html — Tier 1
- Mermaid v11.0.0 release: https://github.com/mermaid-js/mermaid/releases/tag/v11.0.0 — Tier 2
- SARIF 2.1.0 + Errata 01: https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html — Tier 1
- SARIF 2.2 CSD01 public comment (ends 18 Nov 2026): https://www.oasis-open.org/2026/10/20/invitation-to-comment-on-static-analysis-results-interchange-format-sarif-version-2-2-csd01-ends-18-november-2026/ — Tier 1
- CISA KEV: https://www.cisa.gov/known-exploited-vulnerabilities-catalog — Tier 1
- EPSS: https://www.first.org/epss/ — Tier 1
- CVSS v4.0 metric groups: https://blog.purplewasp.com/cvss-is-not-risk-vulnerability-prioritisation/ — Tier 3 (explains v4 groups; spec itself is FIRST)
- CycloneDX / SPDX minimums (BSI TR-03183-2 v2.1.0, 2025-08-20): https://www.bsi.bund.de/.../BSI-TR-03183-2_v2_1_0.pdf — Tier 1
- osv-scanner releases (v2.7.0): https://github.com/google/osv-scanner/releases — Tier 2
- MCP specification revisions: https://modelcontextprotocol.io/specification/2025-11-25/changelog — Tier 1
- AGENTS.md: https://agents.md/ — Tier 1
- Agentic AI Foundation announcement (MCP, goose, AGENTS.md): https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation — Tier 1
- WCAG 2.2 (5 Oct 2023), incl. 2.5.8 / 2.4.11 / 2.4.13: https://www.w3.org/TR/WCAG22/ — Tier 1
