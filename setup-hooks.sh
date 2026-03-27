#!/bin/sh
# MT Push Notification — Claude Code Hooks Setup Script
# Usage: curl -sL https://raw.githubusercontent.com/Jagastudio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
#
# Adds MT Push notification hooks to ~/.claude/settings.json.
# Requires Node.js (always available if Claude Code is installed).
# Supports macOS, Linux, and Windows (WSL).

set -e

DEVICE_SECRET="${1:-}"

# --- Validation ---
if [ -z "$DEVICE_SECRET" ]; then
  echo "Error: Device Secret is required."
  echo ""
  echo "Usage:"
  echo "  curl -sL https://raw.githubusercontent.com/Jagastudio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET"
  echo ""
  echo "Get your Device Secret from MT → Settings → Push Notifications."
  exit 1
fi

if [ ${#DEVICE_SECRET} -lt 10 ]; then
  echo "Error: Device Secret looks too short. Please check and try again."
  exit 1
fi

# --- Check for Node.js ---
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required but not found."
  echo "Claude Code requires Node.js, so it should already be installed."
  echo "Install Node.js from https://nodejs.org/ and try again."
  exit 1
fi

# --- Run Node.js to merge hooks ---
node -e '
const fs = require("fs");
const path = require("path");

const secret = process.argv[1];
const claudeDir = path.join(process.env.HOME || process.env.USERPROFILE, ".claude");
const settingsFile = path.join(claudeDir, "settings.json");

const stopHook = {
  type: "command",
  command: `curl -s -X POST https://mt-push.jaga-farm.com/v1/notify -H '\''Content-Type: application/json'\'' -d '\''{"token":"${secret}","event":"agent-done","message":"Task complete"}'\'' > /dev/null 2>&1 &`
};

const notifHandler = {
  matcher: "permission_prompt",
  hooks: [{
    type: "command",
    command: `curl -s -X POST https://mt-push.jaga-farm.com/v1/notify -H '\''Content-Type: application/json'\'' -d '\''{"token":"${secret}","event":"agent-input","message":"Permission needed"}'\'' > /dev/null 2>&1 &`
  }]
};

// Create ~/.claude/ if needed
if (!fs.existsSync(claudeDir)) {
  fs.mkdirSync(claudeDir, { recursive: true });
}

// Load or create settings
let settings = {};
if (fs.existsSync(settingsFile)) {
  // Check for duplicates
  const raw = fs.readFileSync(settingsFile, "utf8");
  if (raw.includes("mt-push.jaga-farm.com")) {
    console.log("MT Push hooks are already configured in " + settingsFile);
    console.log("To reconfigure, remove the existing mt-push entries first.");
    process.exit(0);
  }

  // Backup
  fs.copyFileSync(settingsFile, settingsFile + ".bak");
  console.log("Backed up existing settings to " + settingsFile + ".bak");

  settings = JSON.parse(raw);
}

// Ensure hooks structure
if (!settings.hooks) settings.hooks = {};

// Add Stop hook
if (!settings.hooks.Stop) {
  settings.hooks.Stop = [{ hooks: [stopHook] }];
} else if (settings.hooks.Stop[0] && settings.hooks.Stop[0].hooks) {
  settings.hooks.Stop[0].hooks.push(stopHook);
} else {
  settings.hooks.Stop.push({ hooks: [stopHook] });
}

// Add Notification hook
if (!settings.hooks.Notification) {
  settings.hooks.Notification = [notifHandler];
} else {
  settings.hooks.Notification.push(notifHandler);
}

// Write
fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + "\n");
console.log("Settings saved to " + settingsFile);
' "$DEVICE_SECRET"

echo ""
echo "✅ MT Push hooks installed successfully!"
echo ""
echo "  Stop hook     → agent-done (task completion)"
echo "  Notification  → agent-input (permission needed)"
echo ""
echo "Restart Claude Code for hooks to take effect."
