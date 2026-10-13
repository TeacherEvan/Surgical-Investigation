# Mermaid Best Practices — Reference

Used when generating diagrams for surgical-investigation reports (Step 8a, HTML output).

## Size Limits

- Keep diagrams under **50 nodes** — larger diagrams become unreadable in HTML
- Use **subgraphs** to group related nodes
- Break very large systems into multiple diagrams (Backend, Frontend, Research, Entire — separate diagrams)

## Naming

- Use consistent naming: `S1`, `S2` for steps; descriptive names for concepts (`DependencyAudit`, `BestPractices`)
- Avoid spaces in node IDs — use CamelCase or underscore
- Label nodes clearly: `S1["Step 1: Scope Definition"]`

## Subgraph Usage

Group by concern:

```mermaid
graph TB
    subgraph Skill["Surgical-Investigation Skill"]
        S0["Mode Selection"]
        S05["Strategy Selection"]
    end
```

This improves readability and keeps the Entire-Project diagram manageable.

## Edge Styles

| Style | Use |
|-------|-----|
| `-->` (default) | Normal flow |
| `-.->` | Optional/dependent flow |
| `==>` | Strong dependency |
| `-.->|with label` | Labeled dependency |

## Color Coding

Use fill colors for categories (optional but recommended):
- Skill steps: `fill:#f9f,stroke:#333` (pink/purple)
- References: `fill:#bbf,stroke:#333` (blue)
- Output formats: `fill:#bfb,stroke:#333` (green)
- External skills: `fill:#fbf,stroke:#333` (light purple)

## Common Patterns for This Skill

**Pipeline:**
```mermaid
graph TB
    A[Step 1] --> B[Step 2] --> C[Step 3] --> D[Step 4]
```

**Parallel (Full-Sweep):**
```mermaid
graph TB
    FS[Full-Sweep] --> CF[codebase-first]
    FS --> TD[targeted-docs]
    FS --> ED[error-driven]
```

**Orchestration (Skill Composition):**
```mermaid
graph TB
    SI[Surgical-Investigation] -.-> SO[surgical-orchestration]
    SI -.-> SIMPL[surgical-implementation]
```

**Comparative Decision Tree (Country A vs Country B):**
```mermaid
graph TB
    Start([Start: Profile
Criteria]) --> A{Option A
Eligible?}
    Start --> B{Option B
Eligible?}
    
    subgraph OptionA["Option A Pathways"]
        A -->|Yes| A1[Pathway A1
Best If...]
        A -->|No| A2[Pathway A2
Alternative]
    end
    
    subgraph OptionB["Option B Pathways"]
        B -->|Yes| B1[Pathway B1
Best If...]
        B -->|No| B2[Pathway B2
Alternative]
    end
    
    subgraph Fallback["Fallback Options"]
        Start --> C[Fallback C]
        Start --> D[Fallback D]
    end
    
    A1 --> Compare[Comparative
Decision Matrix]
    B1 --> Compare
    C --> Compare
    D --> Compare
    Compare --> Decision{Decision:
Score × Weight}
```

**Parallel Timeline with Shared Foundation:**
```mermaid
gantt
    title Comparative Timeline: Option A vs Option B
    dateFormat YYYY-MM-DD
    section Shared Foundation
    Common Prereq 1        :crit, s1, 2024-01-01, 30d
    Common Prereq 2        :crit, s2, after s1, 14d
    
    section Option A
    A-Specific Step        :a1, after s2, 21d
    A-Decision             :crit, a2, after a1, 7d
    
    section Option B
    B-Specific Step        :b1, after s2, 28d
    B-Decision             :crit, b2, after b1, 7d
    
    section Convergent Settlement
    Housing                :settle1, after a2, 30d
    Banking                :settle2, after b2, 14d
```

## Testing Diagrams

Always verify Mermaid syntax before committing:
- Use an online Mermaid editor or VS Code extension
- Check that diagram renders in the HTML template
- Confirm all node references exist in the code

If a diagram fails to render:
- The HTML report will show a placeholder message
- The report remains usable (diagrams are decorative, not functional)
