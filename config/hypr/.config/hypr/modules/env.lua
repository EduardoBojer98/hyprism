-- Environment for apps started inside Hyprland only (KDE never sees these).

-- Render on the AMD iGPU only, so the NVIDIA dGPU can sleep. The link comes from the host step
-- system/hosts/rog-flow-x13/20-igpu.sh; without it Hyprland picks a GPU itself instead of failing.
-- io.open, not os.execute: os.execute always fails inside Hyprland ("No child processes").
local gpu = io.open("/dev/dri/amd-igpu", "r")
if gpu then
    gpu:close()
    hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-igpu")
end

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- VS Code, Chrome and other Electron apps run natively on Wayland
hl.env("QT_QPA_PLATFORMTHEME", "kde")          -- Qt/KDE apps (Dolphin, ...) keep Breeze Dark + Papirus, same as in Plasma
-- Cursor: Settings > Appearance > Cursor saves it in settings/theme.lua (folder name, not the title)
local tok, theme = pcall(require, "settings.theme")
theme = tok and type(theme) == "table" and theme or {}
local cursor = theme.cursor ~= nil and theme.cursor ~= "" and theme.cursor or "default"  -- the system's cursor (/usr/share/icons/default)
local size = tostring(theme.cursor_size or 24)
hl.env("XCURSOR_THEME", cursor)
hl.env("XCURSOR_SIZE", size)
hl.env("HYPRCURSOR_THEME", cursor)
hl.env("HYPRCURSOR_SIZE", size)

-- Language & Region (Settings app writes settings/language.lua): LANG, LANGUAGE and LC_* for apps
-- started in this session. KDE keeps its own language.
local ok, lang = pcall(require, "settings.language")
if ok and type(lang) == "table" then for k, v in pairs(lang) do hl.env(k, v) end end
