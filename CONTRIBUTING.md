# Contributing

Thanks for helping keep Event Calendar alive.

The Plasma 6 work lives on the `master` branch. If you are not sure which
branch your change should target, open an issue first.

## Quick start

1. Fork the repo.
2. Clone the branch you want to work on:

```bash
git clone -b master https://github.com/ALikesToCode/plasma-applet-eventcalendar.git
cd plasma-applet-eventcalendar
```

3. Install the widget locally:

```bash
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

Run the automated checks that cover your change:

```bash
node --test tests/*.test.js
python3 -m unittest discover -s tests -p '*_test.py' -v
find package/contents/ui -name '*.qml' -exec qmllint {} +
shellcheck --severity=warning install update build package/translate/build package/translate/merge
```

Please also include manual test steps in your PR. At minimum:

- Open the widget settings.
- Toggle your change and verify it applies after clicking Apply/OK.
- If the change touches Google login, verify a login flow.

## Pull requests

Include:

- What changed and why.
- Screenshots for UI changes.
- Plasma version tested on.
