-- Environment for apps started inside Hyprland only (KDE never sees these).

-- Hybrid graphics: draw on the built-in card only, so the second card can power off. The link comes from
-- modules/nvidia-hybrid (steps/10-igpu-link.sh); without it Hyprland picks a card itself instead of failing.
-- io.open, not os.execute: os.execute always fails inside Hyprland ("No child processes").
for _, link in ipairs({ "/dev/dri/igpu", "/dev/dri/amd-igpu" }) do -- the second is the name before 2.0
    local gpu = io.open(link, "r")
    if gpu then
        gpu:close()
        hl.env("AQ_DRM_DEVICES", link)
        break
    end
end

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- VS Code, Chrome and other Electron apps run natively on Wayland
-- Qt apps: KDE's platform theme where Plasma's integration is installed (Dolphin & co. look as in Plasma);
-- elsewhere Qt's own GTK3 theme, so they follow the light/dark and accent ThemeSync gives GTK (no extra package)
local kde = false
for _, d in ipairs({ "/usr/lib/qt6/plugins", "/usr/lib64/qt6/plugins" }) do
    local f = io.open(d .. "/platformthemes/KDEPlasmaPlatformTheme6.so", "r")
    if f then f:close(); kde = true end
end
hl.env("QT_QPA_PLATFORMTHEME", kde and "kde" or "gtk3")
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
