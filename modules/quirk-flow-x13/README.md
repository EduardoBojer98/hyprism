# Module: quirk-flow-x13

Fixes for one model, the ASUS ROG Flow X13 (GV301QC): the built-in microphone, and cooler power modes.

- **On when:** the product name contains `GV301QC`.
- **Adds:**
  - a WirePlumber rule that puts the sound card on the profile that has the internal microphone;
  - per-mode fan curves, power limits and CPU energy preference, measured on this model
    (`docs/history/thermal-audit.md`).
- **Why a module of its own:** these numbers are right for this model only. A "quirk" module is the place
  for one model's fixes; copy this folder to add another.
- **Tested on:** the owner's Flow X13.
