-- What this computer has, from ~/.config/hyprism/hardware.toml (written by `./install.sh detect`).
-- Loaded first, so every other module can ask HW instead of naming a device:
--   HW.display.internal   "eDP-1" or ""        HW.machine.form   "laptop" | "desktop" | "vm"
--   HW.power.battery      "BAT0" or ""         HW.gpu.hybrid     true | false
-- Your own [override] lines at the end of that file win. A missing file just means "nothing special".
HW = { machine = {}, gpu = {}, display = {}, power = {}, input = {}, radio = {}, peripherals = {}, module = {} }

local function value(text)
    if text == "true" then return true end
    if text == "false" then return false end
    if text:sub(1, 1) == "[" then
        local list = {}
        for item in text:gmatch('"([^"]*)"') do list[#list + 1] = item end
        return list
    end
    return text:match('^"(.*)"$') or tonumber(text) or text
end

local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local file = io.open(config .. "/hyprism/hardware.toml")
if file then
    local section
    for line in file:lines() do
        local name = line:match("^%[([%w_]+)%]")
        local key, text = line:match("^([%w_.]+)%s*=%s*(.-)%s*$")
        if name then
            section = name
        elseif key and section == "override" then
            local sec, k = key:match("^([%w_]+)%.(.+)$")
            if sec then
                HW[sec] = HW[sec] or {}
                HW[sec][k] = value(text)
            end
        elseif key and section then
            HW[section] = HW[section] or {}
            HW[section][key] = value(text)
        end
    end
    file:close()
end
