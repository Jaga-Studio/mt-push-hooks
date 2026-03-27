# MT Push Hooks

[日本語](README.ja.md)

Setup script for [MT — Mosh Terminal](https://jaga-farm.com/mt/) push notifications with Claude Code.

MT uses Claude Code's **Hooks** to guarantee push notifications at the system level — task completion and permission requests reach your iPhone and Apple Watch instantly.

## Quick Setup

```sh
curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
```

Replace `YOUR-DEVICE-SECRET` with the value from MT → Settings → Push Notifications.

**Requirements:** Node.js (always available if Claude Code is installed)

## What It Does

The script adds two hooks to your `~/.claude/settings.json`:

| Hook | Event | When |
|------|-------|------|
| **Stop** | `agent-done` | Claude finishes responding |
| **Notification** | `agent-input` | Claude needs your permission |

- Safely merges with your existing settings (no overwriting)
- Creates a backup before modifying (`settings.json.bak`)
- Skips if MT Push hooks are already configured

## Manual Setup

If you prefer to configure manually, download [`hooks-template.json`](hooks-template.json) and merge it into your `~/.claude/settings.json`.

File locations:
- macOS / Linux: `~/.claude/settings.json`
- Windows: `%APPDATA%\claude\settings.json`

## Getting Started

For full setup instructions including enabling push notifications in the MT app, see the [Getting Started Guide](https://jaga-farm.com/mt/getting-started.html).

## License

MIT
