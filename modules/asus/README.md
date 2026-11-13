# Module: asus

ASUS laptops: charge limit, power modes, fan curves and keyboard light through `asusctl`.

- **On when:** the vendor is ASUS (`machine.tools`) and it is a laptop.
- **Adds:** `asusctl` and ROG Control Center, the `asusd` service, the `asusfan` and `thermlog` tools, and the
  ASUS page in Settings.
- **Without it:** power modes still work through power-profiles-daemon.
- **Tested on:** the owner's Flow X13.
