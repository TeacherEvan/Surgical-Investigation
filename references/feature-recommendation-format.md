# Feature Recommendation Format — Reference

When writing recommendations for the surgical-investigation report (Step 8a, section 7), each recommendation must include feature-level details for interactive/request features.

## Required elements per recommendation

| Element | What it is | Example |
|---------|-----------|---------|
| What | The feature/change | Add a bulk-export endpoint |
| Why | Why it matters | Would unblock multi-pool diversification |
| How (technical) | Implementation detail | `POST /api/v1/batch/export` accepts array of IDs |
| Interactive/control | User-facing interaction | `my-tool export --ids 1,2,3 --format csv` |
| Endpoint | REST/path spec | `GET /api/v1/status` |
| Webhook/event | Alert/notification event name | `app.export.completed`, `app.alert.breach` |
| Widget/visual | Dashboard/widget spec | Slider to adjust range with projected outcome update |
| Effort | Estimated time | 2-3 days |
| Source | Where this came from | Technical architecture subagent + API docs |

## Interactive feature categories to recommend

- **Request features**: new endpoints, bulk operations (`POST` with array payload), filter/query params, pagination, export (`GET` returning file/CSV)
- **Interactive controls**: command-style interactions (`command --param value`), parameter sliders, toggle switches, confirmation dialogs
- **Real-time updates**: webhook events, live ticker, countdown timer, status badges with color-coding
- **Filtering/dashboards**: user-controlled range filters, date range selectors, multi-item allocation sliders

## Pitfall: Don't write vague recommendations

❌ Bad: "Improve the risk engine."
✅ Good: "Add `RiskMonitor.update()` with consecutive breach counter (3 strikes); interactive control: `my-tool risk --update threshold=10%`."

❌ Bad: "Add a dashboard."
✅ Good: "Dashboard widget showing live metric ticker, item cards (green/red/yellow), countdown timer, efficiency metric (output/cost); endpoint: `GET /api/v1/dashboard/summary`."

## When recommendations apply

- Every investigation of a new concept (no existing code) must produce recommendations that specify endpoints/commands because nothing exists yet.
- Every investigation of an existing project must recommend request features (new endpoints) and interactive features (user controls) that improve usability, observability, or automation.