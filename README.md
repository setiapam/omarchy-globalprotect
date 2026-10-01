# GlobalProtect VPN Plugin for Omarchy

An [Omarchy](https://omarchy.org/) shell bar widget and CLI client for Palo Alto GlobalProtect VPN, built on top of `gpclient` (`yuezk/GlobalProtect-openconnect`) with full SAML/SSO support.

## Features

- **Bar Widget**: Native Omarchy shell bar widget with connection status and quick toggle.
- **Config UI**: Click to open settings directly in the bar popup (portal server, username, SAML SSO toggle, browser selection).
- **Auto Package Detection**: Shows an interactive install button directly in the UI if `globalprotect-openconnect` is missing.
- **Security-First Root Helper**: Uses a dedicated, whitelist-only root helper `/usr/local/lib/omarchy/globalprotect-helper` with sudoers NOPASSWD instead of granting blanket root permissions.
- **CLI Interface**: Full CLI suite (`omarchy-globalprotect` with subcommands `up`, `down`, `status`, `config`).

## Installation

```bash
# 1. Symlink or clone into your Omarchy plugins directory:
ln -s ~/Projects/omarchy-globalprotect ~/.config/omarchy/plugins/setiapam.globalprotect

# 2. Run the helper installer (sets up sudoers rule & links commands to ~/.local/bin):
~/.config/omarchy/plugins/setiapam.globalprotect/bin/omarchy-install-service-globalprotect
```

## CLI Usage

```bash
# Check connection status (JSON format)
omarchy-globalprotect status

# Connect to VPN
omarchy-globalprotect up

# Disconnect
omarchy-globalprotect down

# View configuration
omarchy-globalprotect config read-all
```
