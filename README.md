# Surgical-Investigation

**Deep project investigation with two modes: report or build.**

Part of the [AgentSurgery](https://github.com/TeacherEvan/AgentSurgery) surgical-skills set — alongside [surgical-orchestration](https://github.com/TeacherEvan/surgical-orchestration), [Surgical-Implementation](https://github.com/TeacherEvan/Surgical-Implementation), and [Surgical-HermesDotHealth](https://github.com/TeacherEvan/Surgical-HermesDotHealth).

## What It Does

When activated, Surgical-Investigation prompts you to choose between two modes:

### Investigator Mode
Performs a comprehensive investigation of your project and generates an HTML report with:
- **4 Mermaid diagrams**: Backend, Frontend, Research, and Entire-Project architecture
- **Dependency audit**: versions, security status, maintenance status
- **Best practices assessment**: code quality, architecture, testing, security, performance, docs
- **Implementation optimality check**: algorithms, complexity, resources, alternatives, scalability
- **Agent files audit**: skills, memory, config, docs, kanban, tools
- **External research**: Reddit, technical communities, official docs
- **Feature recommendations**: specific, actionable suggestions for what the project should add next
- **Interactive features**: sticky navigation, follow-up request button, IMPLEMENT button

Report saved to `docs/surgical-investigation-report.html`.

### Project-Manager Mode (YOLO Build)
Performs the same investigation, then **builds directly** based on findings — fixes issues, updates dependencies, refactors suboptimal code, adds recommended features. No report for review. Ends with:

> This was the best I can do!

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
- **surgical-orchestration** — multi-agent orchestration spec
- **Surgical-Implementation** — plan-driven implementation pipeline
- **Surgical-HermesDotHealth** — diagnose .hermes folder health
- **Surgical-Investigation** — this skill

## How It Works

1. **Mode selection** — skill prompts you: Investigator or Project-Manager?
2. **Scope definition** — investigation scope is presented and confirmed
3. **Investigation** — 7-step deep dive (mission, dependencies, practices, optimality, agent files, external sources)
4. **Output** — HTML report (Investigator) or direct build (Project-Manager)

## Skill Structure

```
surgical-investigation/
├── SKILL.md              # Skill definition (13.6 KB)
└── templates/
    └── report.html       # HTML report template (21.4 KB)
```

## Author

**Fenrie** — Lea's AI wolf. A protective cyber-partner built with Hermes Agent.

## License

MIT — see [LICENSE](LICENSE).

## Related

- [Hermes Agent](https://github.com/nousresearch/hermes-agent) — the agent runtime
- [Superpowers skills](https://github.com/TeacherEvan/AgentSurgery) — the skill framework this builds on
