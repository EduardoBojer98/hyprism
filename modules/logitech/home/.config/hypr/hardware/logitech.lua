-- Logitech devices (modules/logitech): Solaar applies your saved device settings at login, hidden in the tray.
hl.on("hyprland.start", function()
    hl.exec_cmd("command -v solaar >/dev/null && solaar --window=hide")
end)
