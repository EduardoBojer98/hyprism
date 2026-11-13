-- Hybrid laptop with an NVIDIA card (modules/nvidia-hybrid): hide NVIDIA's EGL driver from apps started in
-- Hyprland, so the card can sleep. Without this every EGL app (Quickshell, hyprpaper...) opens /dev/nvidia0
-- and keeps it awake. ~/.local/bin/nv undoes it for a single app.
-- Set here, not in a shell's profile, so it works whatever shell the session starts from.
-- Only when the desktop is drawn by another card and Mesa is installed: an NVIDIA-only desktop would lose EGL.
-- io.open, not os.execute: os.execute always fails inside Hyprland ("No child processes").
local mesa = "/usr/share/glvnd/egl_vendor.d/50_mesa.json" -- the path of Arch's mesa and Fedora's mesa-libEGL
local f = io.open(mesa, "r")
if f then
    f:close()
    if HW.gpu.discrete == "nvidia" and HW.gpu.primary ~= "" and HW.gpu.primary ~= "nvidia" then
        hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", mesa)
    end
end
