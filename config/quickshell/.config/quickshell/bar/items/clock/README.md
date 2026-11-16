# Bar item: clock

The time and the date, each part your choice, in the theme's clock style (plain, accent, large display or a full-height block). Click opens the calendar.

Its own settings (`bar.items.clock`, or `bar.items["clock#2"]` for a second clock; Settings → Menu Bar → Selected item):

| Setting | Values | Default |
|---|---|---|
| `time` | `false` hides the time | shown |
| `h24` | `true` 14:40, `false` 2:40 PM | `bar.clock24` (shared with the lock screen) |
| `seconds` | `true` / `false` | `bar.seconds` |
| `date` | `true` / `false` | shown (the large display style: hidden) |
| `weekday` | `none`, `short` (Sun), `long` (Sunday) | `short` |
| `day` | `false` hides the day of the month | shown |
| `month` | `none`, `short` (Nov), `long` (November), `number` (11; then day/month/year with `/`) | `short` |
| `year` | `true` adds it | off |
| `first` | `date` or `time` | `date` |
| `separator` | text between date and time | two spaces |
| `custom` | a Qt date pattern of your own, e.g. `"ddd d MMM, HH:mm"`; it replaces everything above | none |

Pattern letters: `d` `dd` `ddd` `dddd` day, `M` `MM` `MMM` `MMMM` month, `yy` `yyyy` year, `H` `HH` 24-hour,
`h` `hh` 12-hour, `mm` minutes, `ss` seconds, `AP` AM/PM; anything in single quotes is printed as written.
In the split style the date sits on the raised step and the time in the accent block (a pattern of your own goes in
the block); a vertical bar stacks the parts.

Shared settings (click, rightClick, scroll, tooltip, enabled): [docs/bar.md](../../../../../../../docs/bar.md).
