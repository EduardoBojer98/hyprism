# Bar item: sysinfo

System info: any readings you pick, in your order, in one item. Click opens the system panel. The tooltip shows
the longer line for each reading and its recent trend.

## Its settings (`bar.items.sysinfo` in `settings.json`)

| Setting | Default | What it does |
|---|---|---|
| `metrics` | `["cpu", "cpu_temp", "ram", "net"]` | Which readings, in this order |
| `mode` | `"compact"` | `"compact"`: icon and number. `"detailed"`: the name too ("cpu 12%") |
| `sparkline` | `true` | The recent trend in the tooltip |
| `interval` | `2` | Seconds between readings |
| `onlyAbove` | `{}` | Show a reading only at or above a level, e.g. `{ "cpu_temp": 70 }` |
| `thresholds` | `{}` | Your own levels per reading, e.g. `{ "cpu": { "warn": 70, "critical": 90 } }` |
| `formats` | `{}` | Your own text per reading, e.g. `{ "ram": "{value} used" }` |
| `icons` | `{}` | Your own glyph per reading |

## Readings

`cpu`, `cpu_temp`, `cpu_freq`, `gpu`, `gpu_temp`, `gpu_vram`, `gpu_power`, `dgpu`, `dgpu_temp`, `dgpu_vram`,
`dgpu_power`, `ram`, `swap`, `disk`, `disk_io`, `net`, `net_down`, `net_up`, `battery`, `battery_power`,
`battery_time`, `fans`, `profile`, `uptime`, `load`.

A reading your computer doesn't have (no battery, no second graphics card, no fan sensor) is skipped. The second
graphics card (`dgpu…`) shows "off" while it is powered down and is never woken to be read.

Example: a laptop row that shows the temperature only when it matters.

```json
"sysinfo": {
  "metrics": ["cpu", "cpu_temp", "ram", "battery_power", "battery_time"],
  "onlyAbove": { "cpu_temp": 70 },
  "mode": "detailed"
}
```

## Add a reading

One entry in `Metrics.qml`'s `registry` (name, glyph, how to read the number and write the text). If the number
isn't measured yet, add an `m_<name>` function to `~/.local/bin/metrics` and a line to `tests/metrics.sh`.
Shared settings: [docs/bar.md](../../../../../../../docs/bar.md).
