# Hyprland only: hide NVIDIA's EGL driver so the RTX 3050 can sleep. Without this every
# EGL app (Hyprland, Quickshell, hyprpaper...) opens /dev/nvidia0 and keeps it awake.
# The login screen runs a fish login shell right before start-hyprland, so this lands in the
# whole session; KDE sessions have XDG_SESSION_DESKTOP=KDE and skip it.
# ~/.local/bin/nv undoes it for a single app.
if status is-login; and test "$XDG_SESSION_DESKTOP" = Hyprland
    set -gx __EGL_VENDOR_LIBRARY_FILENAMES /usr/share/glvnd/egl_vendor.d/50_mesa.json
end
