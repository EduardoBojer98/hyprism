# Contributing

Thanks for helping. Read [docs/CONVENTIONS.md](docs/CONVENTIONS.md) first. It has the rules and naming.

## Set up

```bash
git clone https://github.com/EduardoBojer98/hyprism
cd hyprism
./install.sh --dry-run   # shows every change without making it
```

## Checks

Run all three before a change counts as done:

```bash
tests/lint.sh
```

```bash
docker run --rm -v "$PWD":/mnt/repo:ro archlinux:latest bash /mnt/repo/tests/container-test.sh
```

```bash
docker run --rm -v "$PWD":/mnt/repo:ro fedora:latest bash /mnt/repo/tests/container-test.sh
```

Other test commands:

- `tests/all.sh`: everything CI runs, through Docker (the lint suite, the install test on Arch and Fedora, the
  update test, the system-steps test). `tests/all.sh lint`, `arch`, `fedora`, `update` or `system` runs one part.
- `tests/system-test.sh`: an install in an Arch container that boots systemd, so services, the firewall, the
  login-manager switch and the files in `/etc` really change; uninstall must put each back.
- `tests/lint.sh`: the static checks (QML and Lua parse, colours only in themes, theme contrast, formatting,
  script tests, the docs check `tests/docs.sh`).
- `tests/nested.sh start`: a test desktop in a window, from this checkout, apart from your real session. Use it to
  see a shell change work (`tests/nested.sh shot NAME` takes a screenshot).
- `tests/docs.sh`: every link, path and `./install.sh` command named in the docs exists.
- Desktop-session tests (not in CI: each opens a `tests/nested.sh` window, so run them by hand inside a Hyprland
  session after a shell change): `tests/settings-roundtrip.sh` (a setting reaches settings.json and back),
  `tests/theme-targets.sh` (a theme reaches every program it is pushed to), `tests/performance.sh` (idle CPU and
  memory budget) and `tests/screenshots.sh` (retakes the README pictures).

## Changes

- Branches: `develop` is where work lands (the dev channel); `main` is stable (the stable channel, what a fresh
  clone gets). Work on `develop` or a branch off it, never on `main`. A release fast-forwards `main` to a
  `develop` commit whose CI passed: `git switch main && git merge --ff-only develop && git push`. A fix that
  can't wait goes to `develop` first, then the same fast-forward.
- Use Conventional Commits, one logical change per commit: `feat(bar): …`, `fix(install): …`, `docs: …`.
- A user-visible change adds a line to [CHANGELOG.md](CHANGELOG.md) under "Unreleased", in the same commit.
- Where to add things (a package, a setting, a theme, a bar item, a module): see the "How to add things" table in
  [docs/CONVENTIONS.md](docs/CONVENTIONS.md).
- Never commit secrets. Keep them in `~/.config/secrets.env`, outside the repo.

## Releasing

1. On `develop` with CI green: set `VERSION` (drop `-dev`) and rename "Unreleased" in
   [CHANGELOG.md](CHANGELOG.md) to the version and date, in one `chore(release): X.Y.Z` commit.
2. Wait for CI on that commit (the update test then runs from the previous release tag).
3. Tag it and publish: `git tag -a vX.Y.Z -m vX.Y.Z`, then the fast-forward from "Changes" above, and
   `git push origin develop main vX.Y.Z`.
4. Back on `develop`: set `VERSION` to the next `-dev` and add an empty "Unreleased" section.

The update test picks the newest `v*` tag by itself; `OLD_TAG=v1.1.0` (`docker run -e OLD_TAG=...`) tests an
update from an older one.
