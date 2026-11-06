# GlobalProtect VPN Plugin for Omarchy

An [Omarchy](https://omarchy.org/) shell bar widget and CLI client for Palo Alto
GlobalProtect VPN, built on top of the open-source
[`gpclient`](https://github.com/yuezk/GlobalProtect-openconnect) from
GlobalProtect-openconnect.

The plugin supports **headless SAML + TOTP login**: you provide the portal,
username, password, and TOTP secret, and the plugin obtains the GlobalProtect
session cookies without opening a browser.

> **Why not `openfortivpn`?**
> `openfortivpn` implements the Fortinet FortiGate protocol. GlobalProtect is a
> different protocol from Palo Alto Networks. `gpclient` (GlobalProtect-
> openconnect) is the correct open-source client for GlobalProtect; it is based
> on OpenConnect's `gp` protocol implementation.
>
> The repository's `install-gp-bps.sh` is a legacy helper for the official Palo
> Alto `PanGPLinux` package. It is not used by the open-source `gpclient` flow
> described here.

## Features

- **Bar Widget**: native Omarchy shell bar widget with connection status and a
  quick toggle.
- **Headless SAML + TOTP**: `gpclient` drives the SAML flow through a hidden
  browser wrapper (Xvfb + Chromium). The wrapper completes Keycloak (password,
  TOTP, and Cloudflare Turnstile when present) and forwards the portal callback
  to `gpclient`; the resulting `portal-userauthcookie` is then used for the
  gateway. No browser window appears.
- **Headless gateway auth**: if the gateway asks for its own SAML login, the
  same wrapper runs another hidden Chromium round and forwards that callback
  too. Portal and gateway logins share a TOTP counter so Keycloak does not
  reject a replayed code.
- **Browser fallback**: if you leave the TOTP secret empty, the plugin falls
  back to the normal `gpclient --browser` SAML flow.
- **Password login**: `saml = false` uses the classic username/password flow.
- **Config UI**: edit the portal, credentials, TOTP secret, and advanced flags
  directly from the bar popup.
- **Auto package detection**: shows an install hint if `gpclient` is missing.
- **CLI**: `omarchy-globalprotect` with `up`, `down`, `status`, `auth`,
  `config`, and `install-deps`.

## Installation

```bash
omarchy plugin add https://github.com/setiapam/omarchy-globalprotect.git --enable
```

For local development (before committing/pushing), symlink the working tree:

```bash
ln -s ~/Projects/omarchy-globalprotect \
  ~/.config/omarchy/plugins/setiapam.globalprotect
omarchy plugin enable setiapam.globalprotect
```

Install the dependencies:

```bash
omarchy-pkg-add globalprotect-openconnect python-requests \
  nodejs xorg-server-xvfb chromium
```

The hidden-browser fallback needs Node.js, Chromium, and `xvfb-run`; it never
opens a window on your desktop.

`gpclient` needs root privileges for the tunnel, so connecting uses `pkexec`
(Polkit). Disconnecting uses `pkexec` only when a session is actually active.

When developing from a local checkout, changes to plugin QML are only picked up
after a shell restart. Omarchy's plugin hot-reload rescans the manifest but
Quickshell keeps the compiled component cached because the plugin directory
lives outside the shell config folder:

```bash
omarchy-restart-shell
```

## Configuration

Open the bar widget and expand **Settings**, or edit
`~/.config/globalprotect/config` (mode 600):

```ini
portal = vpn.bps.go.id
gateway =
username = setia.pambudi
password = your-password
saml = true
totp = JBSWY3DPEHPK3PXP
headless = true
browser = default
```

### TOTP secret

The `totp` value can be:

- a Base32 secret: `JBSWY3DPEHPK3PXP`
- an `otpauth://` URI:
  `otpauth://totp/BPS:setia.pambudi?secret=JBSWY3DPEHPK3PXP&digits=6&period=30&algorithm=SHA1`
- a literal 6/8 digit code, for a one-shot manual login (not automatic)

For BPS, the Keycloak login asks for the username **without** `@bps.go.id`.
The plugin strips `@bps.go.id` automatically if you enter it.

### How the headless flow works

1. `gpclient connect vpn.bps.go.id --browser <wrapper>` starts the portal
   prelogin. Because SAML is required, it launches the hidden-browser wrapper.
2. The wrapper starts Chromium under Xvfb and opens gpclient's local auth URL.
   `omarchy-globalprotect-auth-browser` selects **SSO PEGAWAI BPS**, submits the
   username and password, generates the current TOTP code, and solves Cloudflare
   Turnstile if it appears.
3. It follows the Keycloak → broker → GlobalProtect ACS redirects and forwards
   the `globalprotectcallback:` payload (or `prelogin-cookie` /
   `portal-userauthcookie`) to gpclient's auth socket.
4. `gpclient` fetches the portal config and gets the `portal-userauthcookie`
   from its own portal session, which the gateway accepts. If the gateway asks
   for a separate SAML login, the wrapper handles that round too.
5. `gpclient` submits the HIP report required by the BPS gateway (`--hip`), then
   builds the tunnel. No browser window is shown.

When the portal offers more than one gateway, set one explicitly in the config
(`gateway = vpn-gw01.bps.go.id`). `gpclient` 2.5.x removed `--auto-gateway`;
without `--gateway` it prompts on a TTY and fails in a non-interactive session.

### Security notes

- The config file is written with mode `0600`; the password and TOTP secret are
  stored in plain text because the plugin has no keyring dependency. Treat the
  file like an SSH private key.
- The helper runs as your user and only prints the session cookies to
  `gpclient`; it never sends the password anywhere except the configured
  identity provider.
- `ignore-tls-errors = false` is the default. Only enable it for a trusted
  portal with a broken certificate chain.

## CLI usage

```bash
# Connection status (JSON)
omarchy-globalprotect status

# Connect / disconnect
omarchy-globalprotect up
omarchy-globalprotect down

# Verify the login without printing the session cookies
omarchy-globalprotect auth --check

# Run the headless SAML + TOTP login and print the auth JSON
omarchy-globalprotect auth

# Debug a login by saving each HTML page
omarchy-globalprotect auth --dump-dir /tmp/gp-auth

# Read/write configuration
omarchy-globalprotect config read-all
omarchy-globalprotect config set totp JBSWY3DPEHPK3PXP
```

## Troubleshooting

### `gpclient` is not installed

```bash
omarchy-pkg-add globalprotect-openconnect python-requests \
  nodejs xorg-server-xvfb chromium
```

The hidden-browser fallback needs Node.js, Chromium, and `xvfb-run`; it never
opens a window on your desktop.

If you previously installed the official Palo Alto `PanGPLinux` package
manually, remove its `/usr/share/applications/gpgui.desktop` (or use pacman's
`--overwrite`) if pacman reports a file conflict. The open-source package
provides `gpclient`, `gpauth`, and `gpservice`; it does not replace the official
`PanGPS` daemon.

### "Username or password is incorrect"

Check the username/password in the settings. For BPS, use the bare username
(no `@bps.go.id`). The same message is returned for an unknown user and a wrong
password.

### "The TOTP code was rejected"

- Check that the secret is Base32 and copied completely.
- Make sure the system clock is correct (`timedatectl`).
- If the server clock is offset, try `--totp-skew -1` or `--totp-skew 1` with
  `omarchy-globalprotect auth` to confirm, then keep the working value.
- If you reconnect within the same 30-second window and the server rejects the
  reused code, wait for the next code before toggling the VPN again.

### "Cloudflare Turnstile/CAPTCHA challenge"

The BPS Keycloak theme includes a Cloudflare Turnstile widget. In our testing
the server accepted an empty token for the username/password step (it returned
the normal "invalid username or password" error), so the widget does not appear
to be enforced there. If BPS starts enforcing it after valid credentials, the
helper will report this error; use the browser fallback (`headless = false`) or
a headed browser implementation.

### The VPN is connected but an internal website keeps spinning

The tunnel can be healthy while the browser still fails because the browser
uses DNS-over-HTTPS and bypasses the VPN DNS. `community.bps.go.id` resolves to
`10.0.11.52` via the tunnel; a DoH-enabled browser may resolve it elsewhere.

Disable secure DNS/DoH in the browser:

- **Brave/Chromium**: `brave://settings/security` or
  `chrome://settings/security` → **Use secure DNS** → off (or use your current
  service provider), then clear `brave://net-internals/#dns`.
- **Firefox**: Settings → Privacy & Security → **Enable secure DNS** → off.

Verify from a terminal:

```bash
getent ahosts community.bps.go.id   # should print 10.0.11.52
curl -I https://community.bps.go.id/
```

### "Gateway reports notunnel" / "No IP address received"

When you are on the BPS internal LAN, the internal gateway intentionally
returns `notunnel` / no tunnel IP: you already have internal network access, so
no tunnel is created. Disconnect from the internal LAN to use an external
gateway and get a full tunnel. This is a server-side policy, not an
authentication failure.

### The login succeeds but the tunnel does not start

Run the CLI directly to see `gpclient` output:

```bash
omarchy-globalprotect up
```

Check that `pkexec` can elevate and that `/var/run/gpclient.lock` is writable by
root. Also make sure no other `gpclient` instance is running.

### "The input device is not a TTY"

`gpclient` 2.5.x removed `--auto-gateway`. When the portal lists several
gateways it prompts for a choice, which fails in the plugin's non-interactive
session. Set the gateway explicitly:

```bash
omarchy-globalprotect config set gateway vpn-gw01.bps.go.id
```

`vpn-gw02.bps.go.id` is the other external BPS gateway if the first one is
unreachable.

### Session expires / reconnect

GlobalProtect sessions expire. Just toggle the widget again; the plugin will
run the headless SAML/TOTP flow and obtain fresh cookies.

## Uninstall

```bash
omarchy plugin remove setiapam.globalprotect
```

Your config at `~/.config/globalprotect/` is preserved.
