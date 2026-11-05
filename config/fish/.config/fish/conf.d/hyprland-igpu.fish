# Hyprland only: hide NVIDIA's EGL driver so the dGPU (here an RTX 3050) can sleep. Without this every
# EGL app (Hyprland, Quickshell, hyprpaper...) opens /dev/nvidia0 and keeps it awake.
# The login screen runs a fish login shell right before start-hyprland, so this lands in the
# whole session; KDE sessions have XDG_SESSION_DESKTOP=KDE and skip it.
# ~/.local/bin/nv undoes it for a single app.
# Only on hybrid laptops: the NVIDIA driver loaded, Mesa present, and another GPU to draw on (an NVIDIA-only
# desktop would lose EGL). Without fish as the login shell this simply doesn't run: nothing breaks.
if status is-login; and test "$XDG_SESSION_DESKTOP" = Hyprland; and test -e /proc/driver/nvidia; and test -e /usr/share/glvnd/egl_vendor.d/50_mesa.json
    set -l igpu 0
    for d in /sys/class/drm/card*/device/driver
        test (path basename (readlink -f $d)) != nvidia; and set igpu 1
    end
    test $igpu = 1; and set -gx __EGL_VENDOR_LIBRARY_FILENAMES /usr/share/glvnd/egl_vendor.d/50_mesa.json
end
