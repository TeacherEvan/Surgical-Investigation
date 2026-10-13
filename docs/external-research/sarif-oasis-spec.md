# External Research: OASIS SARIF 2.1.0 & GitHub Code Scanning Specification

> **Tier:** Tier 1 (Official Specification & Vendor Documentation)  
> **Source:** OASIS SARIF v2.1.0 Standard & GitHub Code Scanning Documentation  
> **Retrieved:** 2026-10-13  
> **Strategy:** `targeted-docs` + `rule-id-driven`  

---

## 1. Schema Hierarchy & Required Top-Level Fields

A compliant SARIF document for GitHub Code Scanning must satisfy:

```json
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "<ToolName>",
          "version": "<SemVer>",
          "rules": [ ... ]
        }
      },
      "results": [ ... ]
    }
  ]
}
```

- `$schema`: Must reference the 2.1.0 JSON schema.
- `version`: Must be exact string `"2.1.0"`.
- `runs`: Array with at least one run object.
- `tool.driver.name`: String identifying the tool (e.g. `Surgical-Investigation`).
- `tool.driver.rules`: Array of `ReportingDescriptor` objects declaring each `ruleId` referenced in `results`.

---

## 2. Result Object Requirements for GitHub Annotations

For GitHub Code Scanning to display PR annotations and file line markers:

1. **`ruleId`**: Must match an `id` defined in `tool.driver.rules`.
2. **`level`** (or `defaultConfiguration.level` on the rule):
   - `"error"`: Surfaces as a high-severity alert / failing check.
   - `"warning"`: Surfaces as a medium-severity alert.
   - `"note"`: Surfaces as low-severity / informational finding.
   - `"none"`: Informational only.
3. **`message.text`**: Clear, plain-text summary of the finding.
4. **`locations`**:
   - `physicalLocation.artifactLocation.uri`: Relative path from project root (e.g., `SKILL.md`, `package.json`). Must NOT include leading slashes or machine-local paths.
   - `physicalLocation.artifactLocation.uriBaseId`: Typically `"PROJECTROOT"` or `"%SRCROOT%"`.
   - `physicalLocation.region`: Contains `startLine` (1-indexed), `startColumn`, `endLine`, `endColumn`.

---

## 3. Custom Properties (`properties`)

SARIF allows arbitrary extensible properties under `results[].properties`:
- `priority`: `"high" | "medium" | "low"`
- `why`: Rationale for recommendation
- `what`: Specific change to make
- `endpoint`: Target endpoint or CLI command
- `interactiveControl`: User-facing interaction/control
- `effort`: Estimated implementation time
- `source`: Research citation with credibility tier

This enables rich metadata preservation while remaining 100% compliant with standard SARIF viewers.
