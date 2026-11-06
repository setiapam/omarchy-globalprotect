#!/bin/bash
# Install the passwordless GlobalProtect helper used by this plugin.
#
# Run once after installing/updating the plugin:
#   ./install-gp-helper.sh
#
# It installs a root-owned helper and a sudoers rule that allows only that
# helper, mirroring the OpenFortiVPN plugin. After this, connect/disconnect no
# longer prompts for a sudo/polkit password.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SRC="$PLUGIN_DIR/lib/globalprotect-helper"
HELPER_DIR="/usr/local/lib/omarchy"
HELPER_PATH="$HELPER_DIR/globalprotect-helper"
SUDOERS_FILE="/etc/sudoers.d/omarchy-globalprotect"

[[ -f "$HELPER_SRC" ]] || { echo "Helper source not found: $HELPER_SRC" >&2; exit 1; }

echo "==> Installing $HELPER_PATH"
sudo install -d -o root -g root -m 0755 "$HELPER_DIR"
sudo install -o root -g root -m 0755 "$HELPER_SRC" "$HELPER_PATH"

echo "==> Configuring sudoers rule for passwordless VPN management"
{
  echo "%wheel ALL=(ALL) NOPASSWD: $HELPER_PATH"
  echo "%sudo  ALL=(ALL) NOPASSWD: $HELPER_PATH"
} | sudo tee "$SUDOERS_FILE" >/dev/null
sudo chmod 0440 "$SUDOERS_FILE"

if ! sudo visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
  echo "ERROR: sudoers syntax check failed — removing invalid file" >&2
  sudo rm -f "$SUDOERS_FILE"
  exit 1
fi

echo "✓ Passwordless helper installed: $HELPER_PATH"
