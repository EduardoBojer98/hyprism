#!/usr/bin/env bash
# Fails when two binds take the same key combination in the same submap. Runs modules/binds.lua under plain
# lua with a stub `hl` and a full fake laptop in HW, so every hardware bind is registered.
# Run by tests/lint.sh (CI) or by hand: tests/keybinds.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
lua=$(command -v lua || command -v lua5.4 || true)
if [[ -z $lua ]]; then
    echo "xx lua not found (Arch: lua)"
    exit 1
fi
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
: >"$t/monswitch.conf" # the shared-monitor bind exists only with this file
fail=0
# check NAME CONDITION: the condition is evaluated here
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

out=$(
    XDG_CONFIG_HOME=$t "$lua" - config/hypr/.config/hypr/modules/binds.lua 2>&1 <<'LUA'
-- any hl.dsp.a.b.c(...) returns a token
local function dsp() return setmetatable({}, { __index = function(self) return self end, __call = function() return "dispatcher" end }) end
local seen, clash, count, submap = {}, 0, 0, "(main)"
hl = {
    dsp = dsp(),
    on = function() end,
    bind = function(keys, _, opts)
        opts = opts or {}
        local mods, k = {}, nil
        for part in (keys .. "+"):gmatch("%s*(.-)%s*%+") do mods[#mods + 1] = part end
        k = table.remove(mods):lower()
        for i, m in ipairs(mods) do mods[i] = m:upper() end
        table.sort(mods)
        local combo = (opts.release and "release " or "") .. table.concat(mods, "+") .. "+" .. k
        local id = (opts.description or keys):match("^[^|]*")
        local where = submap .. ": " .. combo
        if seen[where] then
            print("xx " .. where .. " is bound twice: " .. seen[where] .. " and " .. id)
            clash = clash + 1
        end
        seen[where] = id
        count = count + 1
    end,
    define_submap = function(name, fn) local old = submap; submap = name; fn(); submap = old end,
}
HW = { machine = { form = "laptop" }, display = { internal = "eDP-1" },
       power = { backlight = "intel_backlight", kbd_backlight = "tpacpi::kbd_backlight", profiles = true },
       input = { touchpad = true } }
package.path = "config/hypr/.config/hypr/modules/?.lua;" .. package.path
dofile(arg[1])
print(count .. " binds, " .. clash .. " clashes")
os.exit(clash == 0 and 0 or 1)
LUA
)
status=$?
[[ $status -eq 0 ]] || echo "$out"
check "no key combination is bound twice (${out##*$'\n'})" '((status == 0))'
exit "$fail"
