#!/bin/sh
# MT Push Notification — Claude Code Hooks Setup Script
# Usage: curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
#
# Downloads mt-push-notify.sh to ~/.claude/hooks/ and adds hooks to settings.json.
# Requires Node.js (always available if Claude Code is installed).
# Supports macOS, Linux, and Windows (WSL).

set -e

# --- Parse arguments ---
DEVICE_SECRET=""
CLEANUP_SECRET=""
AUTO_YES=false

while [ $# -gt 0 ]; do
  case "$1" in
    --cleanup)
      shift
      CLEANUP_SECRET="${1:-}"
      shift
      ;;
    --yes)
      AUTO_YES=true
      shift
      ;;
    *)
      if [ -z "$DEVICE_SECRET" ]; then
        DEVICE_SECRET="$1"
      fi
      shift
      ;;
  esac
done

SCRIPT_URL="https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/mt-push-notify.sh"

# --- Validation ---
if [ -z "$DEVICE_SECRET" ]; then
  echo "Error: Device Secret is required."
  echo ""
  echo "Usage:"
  echo "  curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET"
  echo ""
  echo "Options:"
  echo "  --yes                    Skip confirmation prompt"
  echo "  --cleanup OLD-SECRET     Deregister old secret from relay"
  echo ""
  echo "Get your Device Secret from MT → Settings → Push Notifications."
  exit 1
fi

if [ ${#DEVICE_SECRET} -lt 10 ]; then
  echo "Error: Device Secret looks too short. Please check and try again."
  exit 1
fi

if [ -n "$CLEANUP_SECRET" ] && [ ${#CLEANUP_SECRET} -lt 10 ]; then
  echo "Error: Cleanup secret looks too short. Please check and try again."
  exit 1
fi

# --- Check for Node.js ---
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required but not found."
  echo "Claude Code requires Node.js, so it should already be installed."
  echo "Install Node.js from https://nodejs.org/ and try again."
  exit 1
fi

# --- Confirmation prompt ---
if [ "$AUTO_YES" = false ]; then
  echo ""
  echo "MT Push Hooks Setup"
  echo "==================="
  echo ""
  echo "This script will:"
  echo "  1. Create ~/.claude/hooks/mt-push-notify.sh"
  echo "  2. Modify ~/.claude/settings.json (backup will be created)"
  if [ -n "$CLEANUP_SECRET" ]; then
    echo "  3. Deregister old secret from relay server"
  fi
  echo ""
  echo "Note: This modifies your Claude Code configuration."
  echo "We are not responsible for any issues that may arise."
  echo "If you prefer, you can set up manually:"
  echo "  https://jaga-farm.com/mt/getting-started.html"
  echo ""
  # Use /dev/tty for interactive input (works even when piped via curl | sh)
  if [ -t 0 ] || [ -e /dev/tty ]; then
    printf "Proceed? [y/N] " > /dev/tty
    read -r REPLY < /dev/tty
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
      echo "Aborted. No changes were made."
      exit 0
    fi
  else
    echo "Error: Non-interactive mode. Use --yes to skip confirmation."
    exit 1
  fi
  echo ""
fi

# --- Download and install mt-push-notify.sh ---
HOOKS_DIR="$HOME/.claude/hooks"
SCRIPT_PATH="$HOOKS_DIR/mt-push-notify.sh"

mkdir -p "$HOOKS_DIR"

echo "Downloading mt-push-notify.sh..."
curl -sL "$SCRIPT_URL" -o "$SCRIPT_PATH.tmp"

# Embed device secret into the script
sed "s|__MT_DEVICE_SECRET__|$DEVICE_SECRET|g" "$SCRIPT_PATH.tmp" > "$SCRIPT_PATH"
rm -f "$SCRIPT_PATH.tmp"
chmod +x "$SCRIPT_PATH"
echo "Installed: $SCRIPT_PATH"

# --- Update settings.json ---
node -e '
const fs = require("fs");
const path = require("path");

const scriptPath = process.argv[1];
const claudeDir = path.join(process.env.HOME || process.env.USERPROFILE, ".claude");
const settingsFile = path.join(claudeDir, "settings.json");

const stopHook = {
  type: "command",
  command: scriptPath + " stop"
};

const notifHandler = {
  matcher: "permission_prompt",
  hooks: [{
    type: "command",
    command: scriptPath + " notification"
  }]
};

// Create ~/.claude/ if needed
if (!fs.existsSync(claudeDir)) {
  fs.mkdirSync(claudeDir, { recursive: true });
}

// Load or create settings
let settings = {};
let mode = "fresh";

if (fs.existsSync(settingsFile)) {
  const raw = fs.readFileSync(settingsFile, "utf8");

  if (raw.includes("mt-push-notify.sh")) {
    // Already using the script — just refresh the script file (done above)
    console.log("MT Push hooks are up to date. Script refreshed.");
    process.exit(0);
  }

  // Backup
  fs.copyFileSync(settingsFile, settingsFile + ".bak");
  console.log("Backed up existing settings to " + settingsFile + ".bak");
  settings = JSON.parse(raw);

  if (raw.includes("mt-push.jaga-farm.com")) {
    // Old inline curl hooks detected — upgrade
    mode = "upgrade";
    console.log("Upgrading from inline curl hooks to script-based hooks...");

    // Remove old MT hooks from Stop
    if (settings.hooks && settings.hooks.Stop) {
      for (const group of settings.hooks.Stop) {
        if (group.hooks) {
          group.hooks = group.hooks.filter(h =>
            !(h.command && h.command.includes("mt-push.jaga-farm.com"))
          );
        }
      }
      // Clean up empty groups
      settings.hooks.Stop = settings.hooks.Stop.filter(g =>
        !g.hooks || g.hooks.length > 0
      );
    }

    // Remove old MT hooks from Notification
    if (settings.hooks && settings.hooks.Notification) {
      settings.hooks.Notification = settings.hooks.Notification.filter(handler => {
        if (handler.hooks) {
          handler.hooks = handler.hooks.filter(h =>
            !(h.command && h.command.includes("mt-push.jaga-farm.com"))
          );
          return handler.hooks.length > 0;
        }
        return true;
      });
    }
  }
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

if (mode === "upgrade") {
  console.log("Hooks upgraded successfully!");
}
' "$SCRIPT_PATH"

# --- Cleanup old secret ---
if [ -n "$CLEANUP_SECRET" ]; then
  echo "Deregistering old secret from relay..."
  curl -s -X DELETE "https://mt-push.jaga-farm.com/v1/register" \
    -H "Content-Type: application/json" \
    -d "{\"deviceSecret\":\"$CLEANUP_SECRET\"}" > /dev/null 2>&1 || true
  echo "Old secret deregistered."
fi

echo ""
echo "✅ MT Push hooks installed successfully!"
echo ""
echo "  Stop hook     → agent-done (shows Claude's last response)"
echo "  Notification  → agent-input (shows actual permission request)"
echo ""
echo "Restart Claude Code for hooks to take effect."
