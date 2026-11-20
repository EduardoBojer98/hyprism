-- Motion, by preset: the shell names one (ThemeSync: the motion look, or the theme's own hypr.motion), apply_motion()
-- sets it. Settings > Themes > Motion previews each one's window open (MotionPreview.qml mirrors windowsIn / windowsOut).
--   instant  barely there: near-immediate, no pop
--   crisp    fast and linear-ish, a quick fade
--   snappy   short slides, no overshoot (Monolith, look Snappy)
--   slam     fast in with a hard stop, windows drop in from slightly larger (Poster)
--   ease     calm, damped, nothing bouncy (Pebble, look Smooth)
--   spring   soft springs with a small pop-in (look Springy)
--   fade     slow cross-fades, workspaces dissolve instead of sliding
--   minimal  quick fades only, nothing slides or grows (look Minimal, Animations: Reduced)
--   off      animations off (Animations: Off)
hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},   {0.32, 1} } })
hl.curve("easeOutExpo",  { type = "bezier", points = { {0.16, 1},   {0.3, 1}  } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},      {1, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5},  {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0},   {0.1, 1}  } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })
hl.curve("bouncy",       { type = "spring", mass = 1, stiffness = 260, dampening = 19 })

local function set(leaf, speed, curve, style)
    local a = { leaf = leaf, enabled = speed > 0, speed = math.max(speed, 0.1) }
    if curve == "easy" or curve == "bouncy" then a.spring = curve else a.bezier = curve end
    if style then a.style = style end
    hl.animation(a)
end

local PRESETS = {
    instant = function()
        set("windows", 1.5, "quick"); set("windowsIn", 1.2, "quick", "popin 98%"); set("windowsOut", 1, "easeOutQuint", "popin 98%")
        set("fade", 1.5, "quick"); set("workspaces", 1.2, "quick", "fade")
    end,
    crisp = function()
        set("windows", 2.2, "quick"); set("windowsIn", 2, "quick", "popin 96%"); set("windowsOut", 1.4, "easeOutQuint", "popin 96%")
        set("fade", 2, "quick"); set("workspaces", 1.8, "quick", "fade")
    end,
    snappy = function()
        set("windows", 3, "easeOutQuint"); set("windowsIn", 2.6, "easeOutQuint", "slide"); set("windowsOut", 1.6, "easeOutQuint", "popin 95%")
        set("fade", 2.4, "quick"); set("workspaces", 2.6, "easeOutQuint", "slide")
    end,
    slam = function()
        set("windows", 2.6, "easeOutExpo"); set("windowsIn", 2.4, "easeOutExpo", "popin 108%"); set("windowsOut", 1.4, "easeOutQuint", "popin 92%")
        set("fade", 2, "quick"); set("workspaces", 2.4, "easeOutExpo", "slidevert")
    end,
    ease = function()
        set("windows", 4.79, "easy"); set("windowsIn", 4.1, "easy", "popin 92%"); set("windowsOut", 1.6, "almostLinear", "popin 94%")
        set("fade", 3.03, "quick"); set("workspaces", 3.2, "easeOutQuint", "slidefade 12%")
    end,
    spring = function()
        set("windows", 5, "bouncy"); set("windowsIn", 4.4, "bouncy", "popin 86%"); set("windowsOut", 1.8, "almostLinear", "popin 90%")
        set("fade", 3, "quick"); set("workspaces", 3.6, "easy", "slidefade 18%")
    end,
    minimal = function()
        set("windows", 1.8, "easeOutQuint"); set("windowsIn", 1.5, "easeOutQuint", "popin 100%"); set("windowsOut", 1.2, "easeOutQuint", "popin 100%")
        set("fade", 1.5, "easeOutQuint"); set("workspaces", 1.5, "easeOutQuint", "fade")
    end,
    fade = function()
        set("windows", 6, "easeOutQuint"); set("windowsIn", 6, "easeOutQuint", "popin 99%"); set("windowsOut", 4, "almostLinear", "popin 99%")
        set("fade", 6, "almostLinear"); set("workspaces", 6, "almostLinear", "fade")
    end,
}

function apply_motion(name)
    hl.config({ animations = { enabled = name ~= "off" } })
    set("global", 10, "default")
    set("border", 5.39, "easeOutQuint")
    -- a frame of two or more colours turns only when the shell says so (THEME.border_loop: Settings > Windows > Turn it on,
    -- motion Full, not Silent, on AC or allowed on battery). "loop" makes Hyprland draw every frame, so it is off in every
    -- other case. speed: 1 slow (10 s a turn: Hyprland caps speed at 100) .. 10 fast (2 s)
    local loop = THEME.border_loop == true
    hl.animation({ leaf = "borderangle", enabled = loop, speed = loop and math.floor(20 + (10 - math.max(1, math.min(10, THEME.border_speed or 5))) * 80 / 9) or 1,
                   bezier = "linear", style = loop and "loop" or nil })
    ;(PRESETS[name] or PRESETS.ease)()
    set("fadeIn", 1.73, "almostLinear"); set("fadeOut", 1.46, "almostLinear")
    -- Layers: the shell's own (qs-*) skip these (no_anim in rules.lua: it animates them itself); other apps'
    -- layers (launchers, pickers) only fade, in every theme: no pop, no slide.
    set("layers", 2, "easeOutQuint", "fade"); set("layersIn", 2, "easeOutQuint", "fade"); set("layersOut", 1.5, "linear", "fade")
    set("fadeLayersIn", 2, "easeOutQuint"); set("fadeLayersOut", 1.5, "linear")
end

apply_theme()   -- modules/look.lua: the theme's frames, gaps, shadow, blur, and this motion
