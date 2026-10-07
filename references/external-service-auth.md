# External Service Authorization — Investigation Reference

When an external service (Telegram bot, Slack app, Discord bot, GitHub App, etc.) connects and registers but receives zero events/updates:

## Authorization Layers (Check ALL — They Can Conflict)

| Source | Location | What It Controls |
|--------|----------|-------------------|
| Config YAML | `~/.hermes/config.yaml` — `platforms.<service>.allow_from` / `.group_allow_from` | Per-adapter allowlist (DM / group / channel) |
| Env Override | `.env` — `<SERVICE>_ALLOWED_USERS` / `<SERVICE>_ALLOWED_CHANNELS` | Overrides YAML; must include numeric IDs |
| Global Gateway | `.env` / config — `GATEWAY_ALLOWED_USERS` / `GATEWAY_ALLOW_ALL_USERS` | Global gateway allowlist / allow-all flag |
| Service-Specific | BotFather / App settings — webhook URL, allowed updates, privacy mode | Service-side routing and permissions |

## Key Rules

1. **Env overrides YAML** — `<SERVICE>_ALLOWED_USERS` in `.env` takes precedence over `config.yaml` for that service.
2. **Numeric IDs required** — The user's numeric ID (Telegram: `7480895493`, Slack: `U123ABC`, Discord: `123456789012345678`) must appear in BOTH the env allowlist (if set) AND the YAML allowlist (if using YAML-only auth).
3. **Bot identity ≠ User identity** — `<SERVICE>_ID` / `<SERVICE>_BOT_USERNAME` in `.env` is the bot's handle, not a user identity. Verify the correct bot token matches the bot the user messages.
4. **Zero updates = Silent block** — A service that connects (valid token, commands registered) but gets zero events over 10+ minutes of healthy polling/long-polling usually means: wrong bot identity, webhook intercepting updates, or authorization blocking silently before dispatch.
5. **Token format verification** — Bot tokens often have format `<numeric>:<secret>` or `xoxb-...` / `xapp-...`. A broken split across lines (required to avoid secret-redaction masking) must be verified with raw byte inspection, not just `cat`.
6. **Secret redaction** — When investigating config/workspace files, check raw bytes — secret-redaction replaces values with `***` in `cat` output; verify actual token format with `open(..., 'rb')` or `repr()`.

## Common Service-Specific Checks

| Service | Token Format | Auth Env Var | Common Pitfall |
|---------|-------------|--------------|----------------|
| Telegram | `123456:ABC-DEF...` | `TELEGRAM_ALLOWED_USERS` | Webhook set instead of long-polling; privacy mode on |
| Slack | `xoxb-...` / `xapp-...` | `SLACK_ALLOWED_USERS` | App not installed to workspace; wrong signing secret |
| Discord | `Bot MTIz...` | `DISCORD_ALLOWED_USERS` | Missing `message_content` intent; wrong bot user ID |
| GitHub App | `ghs_...` / `ghp_...` | `GITHUB_ALLOWED_USERS` | App not installed on target repo; webhook secret mismatch |

## Investigation Checklist

- [ ] Verify bot/app token format (raw bytes, not redacted output)
- [ ] Check `.env` for `<SERVICE>_ALLOWED_USERS` — present? correct IDs?
- [ ] Check `config.yaml` `platforms.<service>.allow_from` — present? correct IDs?
- [ ] Check global `GATEWAY_ALLOWED_USERS` / `GATEWAY_ALLOW_ALL_USERS`
- [ ] Verify service-side config: webhook URL, allowed updates, intents, privacy mode
- [ ] Confirm user messages the correct bot/app (handle matches token)
- [ ] Test with a known-allowed user ID
- [ ] Check service logs for "update dropped" / "unauthorized" / "forbidden"