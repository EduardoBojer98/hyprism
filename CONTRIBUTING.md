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
  update test). `tests/all.sh lint`, `arch`, `fedora` or `update` runs one part.
- `tests/lint.sh`: the static checks (QML and Lua parse, colours only in themes, theme contrast, formatting,
  script tests, the docs check `tests/docs.sh`).
- `tests/nested.sh start`: a test desktop in a window, from this checkout, apart from your real session. Use it to
  see a shell change work (`tests/nested.sh shot NAME` takes a screenshot).
- `tests/docs.sh`: every link, path and `./install.sh` command named in the docs exists.

## Changes

- Work on a branch, never on `main`.
- Use Conventional Commits, one logical change per commit: `feat(bar): …`, `fix(install): …`, `docs: …`.
- A user-visible change adds a line to [CHANGELOG.md](CHANGELOG.md) under "Unreleased", in the same commit.
- Where to add things (a package, a setting, a theme, a bar item, a module): see the "How to add things" table in
  [docs/CONVENTIONS.md](docs/CONVENTIONS.md).
- Never commit secrets. Keep them in `~/.config/secrets.env`, outside the repo.
