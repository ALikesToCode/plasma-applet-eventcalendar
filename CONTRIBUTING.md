# Contributing

Thanks for helping keep Event Calendar alive.

The Plasma 6 work lives on the `plasma-6` branch. If you are not sure which
branch your change should target, open an issue first.

## Quick start

1. Fork the repo.
2. Clone the branch you want to work on:

```
git clone -b plasma-6 https://github.com/ALikesToCode/plasma-applet-eventcalendar.git
cd plasma-applet-eventcalendar
```

3. Install the widget locally:

```
./install
```

The install script restarts `plasmashell` so you do not have to log out.

## Reporting issues

Please include:

- Plasma version and distro.
- Steps to reproduce.
- Expected vs actual behavior.
- Logs. Two easy options:
  - Run `plasmashell --replace` in a terminal and capture the output.
  - Run `journalctl --user -b | rg eventcalendar`.

If you are reporting Google OAuth problems, do not post tokens, client secrets,
or full redirect URLs. Redact them before sharing.

## Code guidelines

- Keep the existing formatting style in each file.
- Use `i18n` / `i18nc` for user facing strings.
- If you add a new config key, update:
  - `package/contents/config/main.xml`
  - `package/contents/ui/lib/ConfigPage.qml`
- Avoid new runtime dependencies if possible.

## Testing

There are no automated tests. Please include manual test steps in your PR.
At minimum:

- Open the widget settings.
- Toggle your change and verify it applies after clicking Apply/OK.
- If the change touches Google login, verify a login flow.

## Pull requests

Include:

- What changed and why.
- Screenshots for UI changes.
- Plasma version tested on.

