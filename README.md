# GlobalProtect VPN Plugin for Omarchy

An [Omarchy](https://omarchy.org/) shell bar widget and CLI client for Palo Alto GlobalProtect VPN, built on top of `gpclient` (`yuezk/GlobalProtect-openconnect`) with full SAML/SSO support.

## Features

- **Bar Widget**: Native Omarchy shell bar widget with connection status and quick toggle.
- **Config UI**: Click to open settings directly in the bar popup (portal server, gateway, username, SAML SSO toggle, browser selection).
- **Auto Package Detection**: Shows an interactive install button directly in the bar popup if `globalprotect-openconnect` is not found.
- **Polkit Integration**: Elevates privileges natively using `pkexec` when initiating connection.
- **CLI Interface**: Full CLI suite (`omarchy-globalprotect` with subcommands `up`, `down`, `status`, `config`, `install-deps`).

## Installation

Standard Omarchy plugin installation via Git:

```bash
omarchy plugin add https://github.com/setiapam/omarchy-globalprotect.git --enable
```

If `globalprotect-openconnect` is not installed yet, the widget will detect it and offer an **Install Package** button, or install it manually:

```bash
omarchy-pkg-add globalprotect-openconnect
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
