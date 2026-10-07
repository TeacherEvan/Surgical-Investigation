# SARIF Schema Reference — Reference

Used when generating SARIF output from surgical-investigation (Step 7.5, SARIF format).

## SARIF 2.1.0 — Required Fields for Skill Output

```json
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Surgical-Investigation",
          "version": "1.1.0",
          "rules": [
            {
              "id": "DEPENDENCY-AUDIT",
              "name": "Dependency Audit Finding",
              "shortDescription": { "text": "Dependency version or vulnerability finding" },
              "fullDescription": { "text": "Found during Step 3 (Dependency Audit) of surgical-investigation" }
            },
            {
              "id": "PRACTICE-REVIEW",
              "name": "Best Practice Assessment",
              "shortDescription": { "text": "Code quality, architecture, testing, security recommendation" }
            },
            {
              "id": "RECOMMENDATION",
              "name": "Feature Recommendation",
              "shortDescription": { "text": "Specific, actionable recommendation from investigation" }
            }
          ]
        }
      },
      "results": [
        {
          "ruleId": "DEPENDENCY-AUDIT",
          "ruleIndex": 0,
          "message": {
            "text": "Dependency 'axios' at v0.21.0 has a known vulnerability; upgrade to v1.6.0 recommended."
          },
          "properties": {
            "priority": "high",
            "why": "Security vulnerability in dependency",
            "what": "Upgrade to v1.6.0",
            "effort": "15 minutes",
            "source": "GitHub Advisory DB (Tier 2)"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "package.json",
                  "uriBaseId": "PROJECTROOT"
                },
                "region": {
                  "startLine": 1,
                  "startColumn": 1
                }
              },
              "message": {
                "text": "Line referencing dependency version"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

## Key Concepts

- `tool.driver.name`: Skill name (`Surgical-Investigation`)
- `tool.driver.version`: Skill version (`1.1.0`)
- `tool.driver.rules`: Each investigation category = one rule
- `results[].ruleId`: References a rule from `rules[]`
- `results[].message.text`: Human-readable finding
- `results[].properties`: Custom properties for recommendations (`priority`, `why`, `what`, `effort`, `source`)
- `results[].locations[]`: Where in the project the finding applies (file, line, column)

## Mapping Investigation Output to SARIF

| Investigation Section | SARIF `ruleId` | Source |
|----------------------|----------------|--------|
| Dependency Audit (Step 3) | `DEPENDENCY-AUDIT` | Dependency versions, security status |
| Best Practices (Step 4) | `PRACTICE-REVIEW` | Code quality, architecture, testing, security, docs |
| Implementation Optimality (Step 5) | `OPTIMALITY-REVIEW` | Algorithm, complexity, resources, scalability |
| Agent Files (Step 6) | `AGENT-FILES-REVIEW` | Skills, memory, config, docs |
| External Research (Step 7) | `RESEARCH-FINDING` | Credibility-scored findings |
| Recommendations (Step 8a) | `RECOMMENDATION` | Actionable feature suggestions |

## Priority Mapping

SARIF `level` (optional) or custom property `priority`:

| Investigation Priority | SARIF `level` | SARIF Property `priority` |
|----------------------|---------------|---------------------------|
| High | `error` | `high` |
| Medium | `warning` | `medium` |
| Low | `note` | `low` |

## Compatibility

- **GitHub Code Scanning**: Requires `ruleId`, `message.text`, `locations[].physicalLocation.artifactLocation.uri`
- **VS Code SARIF Viewer**: Uses `message.text`, `level`, `rule.name`
- **Static Analysis Tools**: Require `run.tool.driver.name` and `results[].ruleId`

## Common Mistakes

- ❌ Missing `ruleId` — GitHub Code Scanning requires it
- ❌ Missing `message.text` — SARIF viewers show nothing
- ❌ Empty `rules[]` — Each `ruleId` in results must reference a defined rule
- ❌ `artifactLocation.uri` missing — Code scanning cannot map to files
