# Redesign round 4: state

Branch `redesign` (worktree `.claude/worktrees/redesign`), from `develop` at 61ef5d2. Prompt: `docs/redesign-prompt.md`
(untracked in the main checkout). Resume from this file alone.

## Baseline (2026-11-19)

- `bash tests/lint.sh`: pass. `python3 tests/settings-coverage.py`: 244 options, 0 gaps. `bash tests/docs.sh`: pass.
- `tests/all.sh` (Docker): see "Checks" below.
- Nested sweep (session `rd`, 1920x1200, 3 themes x light/dark, desktop, Control Center, launcher, notifications,
  power, calendar, Settings appearance/bar/sound/displays): no QML errors; warnings only for ThemePreview
  wallpapers not drawn yet (`ThemePreview.qml:33`) and Qt text-input focus noise.
- Sweep gotcha: wait 5 s after a theme+mode switch before `shot`, or the capture can be the previous frame.

## Decisions

- Build on the round-3 design; the three themes already differ in type, shape, depth and motion. No new direction
  is forced; polish and close the gaps the audit finds (see PLAN.md for the evaluated directions).

## Done

- Worktree, baseline, screenshots, AUDIT.md, PLAN.md.
- 5bf0857 tokens + no-hardcode guard; e681bbc real controls (tile gating, OSK read-back, bar menu checks).

## Next

- PLAN.md tasks 3-7.
- claude-free failed this session (unrecognized_model free-coding); Explore agents used instead.

## Checks

- tests/all.sh baseline (develop 61ef5d2): lint, install-arch, install-fedora, update-arch, update-fedora, system all ok.
- tests/performance.sh baseline: default bar 0.03 % CPU / 178 MB; sysinfo bar 0.20 % / 333 MB.
