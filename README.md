# MT Push Hooks

[日本語](README.ja.md)

Setup script for [MT — Mosh Terminal](https://jaga-farm.com/mt/) push notifications with Claude Code.

MT uses Claude Code's **Hooks** to send push notifications — task completion and permission requests reach your iPhone and Apple Watch with the **actual content** of what Claude was doing.

## Quick Setup

```sh
curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
```

Replace `YOUR-DEVICE-SECRET` with the value from MT → Settings → Push Notifications.

**Requirements:** Node.js (always available if Claude Code is installed)

## What It Does

The script installs `~/.claude/hooks/mt-push-notify.sh` and adds two hooks to `~/.claude/settings.json`:

| Hook | Event | Notification Content |
|------|-------|---------------------|
| **Stop** | `agent-done` | First 200 chars of Claude's last response |
| **Notification** | `agent-input` | The actual permission request message |

- Safely merges with your existing settings (no overwriting)
- Creates a backup before modifying (`settings.json.bak`)
- Automatically upgrades from older inline curl hooks
- Re-running the script refreshes the notification script without duplicating hooks

## Upgrading

If you previously set up MT Push hooks, just re-run the setup command. It will automatically replace the old inline curl hooks with the new script-based version.

## Manual Setup

If you prefer to configure manually:

1. Download [`mt-push-notify.sh`](mt-push-notify.sh) to `~/.claude/hooks/`
2. Replace `__MT_DEVICE_SECRET__` with your device secret
3. Make it executable: `chmod +x ~/.claude/hooks/mt-push-notify.sh`
4. Merge [`hooks-template.json`](hooks-template.json) into `~/.claude/settings.json`

## Getting Started

For full setup instructions including enabling push notifications in the MT app, see the [Getting Started Guide](https://jaga-farm.com/mt/getting-started.html).

## License

MIT
