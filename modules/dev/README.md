# Module: dev

Tools for writing software: one version manager for Node, PHP, Python and more (mise), and Docker.

- **On when:** only when you ask: `./install.sh --with dev`.
- **Adds:** `mise` (on Fedora from its author's COPR, named before it is enabled), Docker with Compose, and a
  fish snippet that switches tool versions per project folder.
- **Docker** starts on first use, not at boot. The step offers to add you to the `docker` group so you can run
  it without `sudo`; that group can do anything root can, so it asks first.
- **Use it:** `mise use node@22` in a project pins Node there; `mise use -g python@3.13` sets a default.
  `mise ls` shows what is active.
- **Tested on:** Arch and Fedora containers (packages resolve; the fish snippet is skipped without mise).
