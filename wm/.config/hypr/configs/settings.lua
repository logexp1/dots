local activeBorderColor = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local inactiveBorderColor = "rgba(595959aa)"

hl.config({
    input = {
        kb_layout = "my_mod",
        kb_options = "ctrl:swap_lalt_lctl,caps:super,numpad:mac",

        touchpad = {
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },

    general = {
        border_size = 2,

        col = {
            active_border = activeBorderColor,
            inactive_border = inactiveBorderColor,
        },

        gaps_in = 5,
        gaps_out = 5,

        layout = "dwindle",
        no_focus_fallback = true,
    },

    group = {
        col = {
            border_active = activeBorderColor,
            border_inactive = inactiveBorderColor,
        },
        focus_removed_window = false,

        groupbar = {
            col = {
                active = "rgba(00000040)",
                inactive = "rgba(00000020)",
            },
        },
    },

    dwindle = {
        preserve_split = true,
    },

    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.2,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            ignore_opacity = true,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    binds = {
        movefocus_cycles_fullscreen = false,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

local function bezier(name, x0, y0, x1, y1)
    hl.curve(name, { type = "bezier", points = { { x0, y0 }, { x1, y1 } } })
end

bezier("myBezier", 0.05, 0.9, 0.1, 1.05)
bezier("linear", 0.0, 0.0, 1.0, 1.0)
bezier("wind", 0.05, 0.9, 0.1, 1.05)
bezier("winIn", 0.1, 1.1, 0.1, 1.1)
bezier("winOut", 0.3, -0.3, 0, 1)
bezier("slow", 0, 0.85, 0.3, 1)
bezier("overshot", 0.7, 0.6, 0.1, 1.1)
bezier("bounce", 1.1, 1.6, 0.1, 0.85)
bezier("sligshot", 1, -1, 0.15, 1.25)

hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "slow", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "linear" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" }) -- used by rainbow borders and rotating colors
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "bounce", style = "popin" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Last, so a machine without the per-machine file loses nothing above.
require("configs.monitors")
