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
- **Headless SAML + TOTP**: a small Python helper walks the Keycloak/SAML flow,
  generates the TOTP code, and feeds the resulting portal cookies to `gpclient`
  via `--cookie-on-stdin`. If Keycloak presents Cloudflare Turnstile, a hidden
  Chromium (Xvfb) completes the challenge; no browser window appears.
- **Headless gateway auth**: `gpclient` also needs a second SAML login for its
  gateway. A wrapper automates that in the same hidden Chromium and forwards
  the callback to `gpclient`. Portal and gateway logins automatically wait for
  a fresh TOTP window so Keycloak does not reject a replayed code.
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

1. `omarchy-globalprotect-auth` opens
   `https://vpn.bps.go.id/global-protect/login.esp` and follows the
   auto-submitting SAML form to Keycloak.
2. It selects **SSO PEGAWAI BPS**, submits the username and password, and
   generates the current TOTP code from the stored secret.
3. It follows the Keycloak → broker → GlobalProtect ACS redirects and extracts
   `prelogin-cookie` / `portal-userauthcookie` (or the equivalent
   `globalprotectcallback:` payload).
4. The JSON auth result is piped to:
   `gpclient connect vpn.bps.go.id --cookie-on-stdin --browser <wrapper>`.
5. `gpclient` discovers the gateway. If it needs a second SAML login, it
   launches the wrapper; the wrapper runs the hidden Chromium again and
   forwards the gateway callback to `gpclient`.
6. `gpclient` builds the tunnel. No browser is launched.

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

### Session expires / reconnect

GlobalProtect sessions expire. Just toggle the widget again; the plugin will
run the headless SAML/TOTP flow and obtain fresh cookies.

## Uninstall

```bash
omarchy plugin remove setiapam.globalprotect
```

Your config at `~/.config/globalprotect/` is preserved.
