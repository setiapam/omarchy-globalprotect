#!/bin/bash
# -------------------------------------------------------------
# Automated GlobalProtect installer & setup for Arch / Omarchy
# Compatible with official PanGPLinux package provided by BPS
# -------------------------------------------------------------
set -euo pipefail

TAR_DIR="${1:-$HOME/Downloads/PanGPLinux-6.3.3-c42}"

if [ ! -d "$TAR_DIR" ]; then
    echo "Directory $TAR_DIR not found. Please provide path to PanGPLinux folder."
    exit 1
fi

RPM_PKG=$(find "$TAR_DIR" -name "GlobalProtect_UI_rpm-*.rpm" | head -1)
if [ -z "$RPM_PKG" ]; then
    echo "GlobalProtect RPM package not found in $TAR_DIR"
    exit 1
fi

echo "==> Extracting $RPM_PKG..."
TMP_EXTRACT=$(mktemp -d)
trap 'rm -rf "$TMP_EXTRACT"' EXIT

bsdtar -xf "$RPM_PKG" -C "$TMP_EXTRACT"

echo "==> Installing files to /opt/paloaltonetworks/globalprotect..."
sudo -S -p '' mkdir -p /opt/paloaltonetworks
sudo -S -p '' cp -r "$TMP_EXTRACT/opt/paloaltonetworks/globalprotect" /opt/paloaltonetworks/

echo "==> Applying Arch/Omarchy IPC integrity patch to PanGPS..."
python3 - << 'PYEOF'
with open("/opt/paloaltonetworks/globalprotect/PanGPS", "rb") as f:
    data = bytearray(f.read())
idx = data.find(b"/lib32/\x00")
if idx != -1:
    data[idx:idx+8] = b"/etc/\x00\x00\x00"
    with open("/opt/paloaltonetworks/globalprotect/PanGPS", "wb") as f:
        f.write(data)
    print("PanGPS successfully patched.")
else
    print("PanGPS already patched or string not found.")
PYEOF

echo "==> Setting up services & symlinks..."
sudo -S -p '' chmod +x /opt/paloaltonetworks/globalprotect/*
sudo -S -p '' ln -sf /opt/paloaltonetworks/globalprotect/globalprotect /usr/bin/globalprotect
sudo -S -p '' cp /opt/paloaltonetworks/globalprotect/gpd.service /etc/systemd/system/
sudo -S -p '' cp /opt/paloaltonetworks/globalprotect/gp.desktop /usr/share/applications/gpgui.desktop
sudo -S -p '' update-desktop-database /usr/share/applications/

sudo -S -p '' systemctl daemon-reload
sudo -S -p '' systemctl enable --now gpd.service

echo "==> Starting PanGPA in user background..."
pgrep -u "$USER" PanGPA >/dev/null 2>&1 || { /opt/paloaltonetworks/globalprotect/PanGPA start & }

echo "✓ GlobalProtect installation & patch complete!"
