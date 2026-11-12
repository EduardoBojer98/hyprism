# Bar item: memory

The memory in use. The tooltip shows used and total. Click opens the system panel.

Read by the metrics service only while the item is in a bar. Default levels: amber at 85, red at 95 (change
them with `warn` and `critical`). `interval` is the seconds between readings.

For several readings in one item, with your own order, use the `sysinfo` item instead.
Shared settings: [docs/bar.md](../../../../../../../docs/bar.md).
