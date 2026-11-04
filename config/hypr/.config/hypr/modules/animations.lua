-- Motion, by preset: each theme names one (Quickshell Themes.qml, hypr.motion), apply_motion() sets it.
--   instant  barely there: near-immediate, no pop (Monolith)
--   crisp    fast and linear-ish, a quick fade (Console)
--   snappy   short slides, no overshoot (Atlas)
--   slam     fast in with a hard stop, windows drop in from slightly larger (Poster)
--   ease     calm, damped, nothing bouncy (Glass, Canvas, Workstation, Zen, Mist)
--   spring   soft springs with a small pop-in (Pebble, Garden, Halo)
--   fade     slow cross-fades, workspaces dissolve instead of sliding (Noir)
--   off      animations off (Settings > Themes > Animations)
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
        set("windows", 1.5, "quick"); set("windowsIn", 1.2, "quick", "popin 98%"); set("windowsOut", 1, "linear", "popin 98%")
        set("fade", 1.5, "quick"); set("layers", 1.2, "quick", "fade"); set("workspaces", 1.2, "quick", "fade")
    end,
    crisp = function()
        set("windows", 2.2, "quick"); set("windowsIn", 2, "quick", "popin 96%"); set("windowsOut", 1.4, "linear", "popin 96%")
        set("fade", 2, "quick"); set("layers", 1.8, "quick", "fade"); set("workspaces", 1.8, "quick", "fade")
    end,
    snappy = function()
        set("windows", 3, "easeOutQuint"); set("windowsIn", 2.6, "easeOutQuint", "slide"); set("windowsOut", 1.6, "linear", "popin 95%")
        set("fade", 2.4, "quick"); set("layers", 2.4, "easeOutQuint", "slide"); set("workspaces", 2.6, "easeOutQuint", "slide")
    end,
    slam = function()
        set("windows", 2.6, "easeOutExpo"); set("windowsIn", 2.4, "easeOutExpo", "popin 108%"); set("windowsOut", 1.4, "linear", "popin 92%")
        set("fade", 2, "quick"); set("layers", 2.2, "easeOutExpo", "slide"); set("workspaces", 2.4, "easeOutExpo", "slidevert")
    end,
    ease = function()
        set("windows", 4.79, "easy"); set("windowsIn", 4.1, "easy", "popin 92%"); set("windowsOut", 1.6, "almostLinear", "popin 94%")
        set("fade", 3.03, "quick"); set("layers", 3.81, "easeOutQuint", "fade"); set("workspaces", 3.2, "easeOutQuint", "slidefade 12%")
    end,
    spring = function()
        set("windows", 5, "bouncy"); set("windowsIn", 4.4, "bouncy", "popin 86%"); set("windowsOut", 1.8, "almostLinear", "popin 90%")
        set("fade", 3, "quick"); set("layers", 4, "bouncy", "popin 90%"); set("workspaces", 3.6, "easy", "slidefade 18%")
    end,
    fade = function()
        set("windows", 6, "easeOutQuint"); set("windowsIn", 6, "easeOutQuint", "popin 99%"); set("windowsOut", 4, "almostLinear", "popin 99%")
        set("fade", 6, "almostLinear"); set("layers", 5, "almostLinear", "fade"); set("workspaces", 6, "almostLinear", "fade")
    end,
}

function apply_motion(name)
    hl.config({ animations = { enabled = name ~= "off" } })
    set("global", 10, "default")
    set("border", 5.39, "easeOutQuint")
    hl.animation({ leaf = "borderangle", enabled = false, speed = 1, bezier = "linear" })
    ;(PRESETS[name] or PRESETS.ease)()
    set("fadeIn", 1.73, "almostLinear"); set("fadeOut", 1.46, "almostLinear")
    -- The shell's bar, panels, menus and notifications are layers. The shell animates them itself
    -- (a short drop from the bar), so Hyprland only fades them, in every theme: no pop, no slide.
    set("layers", 2, "easeOutQuint", "fade"); set("layersIn", 2, "easeOutQuint", "fade"); set("layersOut", 1.5, "linear", "fade")
    set("fadeLayersIn", 2, "easeOutQuint"); set("fadeLayersOut", 1.5, "linear")
end

apply_theme()   -- modules/look.lua: the theme's frames, gaps, shadow, blur, and this motion
