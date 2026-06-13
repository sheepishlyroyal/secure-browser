#!/bin/bash
# Auto-open Chromium when the desktop session starts, so you land in a browser instead of
# having to click Applications → Web Browser. Persisted in /config (the home dir).
mkdir -p /config/.config/autostart
cat > /config/.config/autostart/chromium.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=Web Browser
Exec=chromium --no-sandbox --start-maximized --no-first-run
X-GNOME-Autostart-enabled=true
Terminal=false
DESK
chown -R abc:abc /config/.config 2>/dev/null || true
