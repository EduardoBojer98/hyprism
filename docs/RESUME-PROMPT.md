# Resume prompt: council refurbish, round 3

Paste everything below the line into a new Claude Code session in `~/Documents/projects/linux-setup`.

---

Continue the council-led refurbish of this repo (the full brief I gave before is summarised here; the details live
in the docs). You lead and do the work; ask me only for decisions that are truly mine, grouped together.

**Read first:** `docs/COUNCIL.md` (scoreboard, what was fixed, what was rejected and why, hard limits),
`docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/INVENTORY.md`, `docs/DESIGN.md`, `docs/THEMES.md`,
`docs/USER-GUIDE.md`. The council brief every reviewer gets is `.council/brief.md` (local, git-excluded; recreate it
from the "Council" section below if it is missing).

**Where we are:** rounds 1 and 2 are scored and fixed. Round 3's fixes are in (settings.json is the one source of
truth via `config/quickshell/.config/quickshell/SettingsSync.qml`; dim before lock; more doctor checks) and fresh
screenshots exist in `.council/shots/`, but the round 3 review has not run. No part has 9.5 from every member yet
(best 9.0).

**Do now:**
1. Re-take the screenshots if any shell file changed since they were taken: the capture scripts are in this session's
   scratchpad, so rewrite them if needed. Rules: check that I'm idle first (pointer and active window unchanged for
   60 s), capture the monitor under the pointer, close every panel between shots, and put my theme and light/dark
   back at the end (read them with `qs ipc call config get appearance theme|mode` first).
2. Run council round 3: seven members, at most 3 agents at a time, each gets only `.council/brief.md`:
   design lead (opus), UX/newcomer (opus), systems engineer (opus), performance (sonnet), code quality (sonnet),
   accessibility (sonnet), security (sonnet). Log raw scores in `.council/feedback.md`, the table in `docs/COUNCIL.md`.
3. Fix what they find: verify each finding against the code first, reject wrong ones with evidence in
   `docs/COUNCIL.md`. Then re-capture and run round 4, and so on, until every part reaches 9.5 from every member
   that judges it, or is logged as a hard limit.

**Known open items** (from round 2): the bar has no keyboard focus path; `ControlCenter.qml` (≈1460 lines) wants
a split into one file per section; launcher, Control Center and dock touch targets in tablet mode beyond the shared
controls; cheat-sheet column balance; one size vocabulary across Settings (Small/Medium/Large/Huge); one
battery/charging notation in the bar; host steps 10–50 need my sudo (`./install.sh steps-done` or
`./install.sh --only host`); Qt theming beyond the GTK3 fallback (qt6ct would be a new package: ask me).

**Council** (if `.council/brief.md` is missing): each member reviews read-only and scores parts 1–16 that their
role judges (1 Settings app, 2 Theme system, 3 Layout, 4 Hyprland core, 5 Bar + Control Center, 6 Launcher /
power menu / cheat sheet, 7 Notifications + OSD, 8 Lock / idle / suspend, 9 Multi-monitor + monswitch,
10 Screenshot, 11 Input devices, 12 Power / GPU, 13 App theming, 14 Installer / doctor / first run, 15 Docs,
16 Code quality + CI). Every score needs evidence (file:line, screenshot, command output). Under 9.5: problem, why,
fix. Output: `SCORES:` line, then per part the costly items, then `TOP 5`.

**Rules that still apply:**
- Repo first, then live: every change goes in the repo, gets applied and verified on this machine.
- After a QML edit, check `qs log` for errors. A new QML file needs its link in `~/.config/quickshell/`
  (`./install.sh --only links`).
- `tests/lint.sh` must pass: QML syntax, Lua, shellcheck, no hardcoded colours, theme contrast, script tests.
  `./install.sh doctor` must be clean.
- Don't send keystrokes or switch themes while I'm using the machine.
- Work on `main`, no extra branches. Commit in small conventional commits when a round is done. Push only when I say.
- Free software only. Every new package is justified in `docs/DECISIONS.md` and needs my OK first.
