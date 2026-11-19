local function rule(class, effects)
    effects.match = { class = class }
    hl.window_rule(effects)
end

-- scratchpads
hl.bind("SUPER + t", hl.dsp.exec_cmd("pypr toggle kitty"))
rule("^(dropdown)$", {
    float = true,
    workspace = "special:scratch_term silent",
    size = { "monitor_w*0.75", "monitor_h*0.6" },
    move = { "monitor_w*0.12", "monitor_h*-2" },
})
rule("^(dropdown-kitty)$", {
    float = true,
    workspace = "special:scratch_kitty silent",
    size = { "monitor_w*0.75", "monitor_h*0.6" },
    move = { "monitor_w*0.12", "monitor_h*-2" },
    opacity = "0.9 0.8",
})

for _, class in ipairs({
    "^(org.kde.polkit-kde-authentication-agent-1)$",
    "^(pavucontrol)$",
    "^(nm-connection-editor)$",
    "^(xdg-desktop-portal-gtk)$",
    "^(blueman-manager)$",
    "^([Zz]oom)$",
    "^(Slack)$",
    "^(rofi)$",
    "^(PulseUI)$",
}) do
    rule(class, { float = true })
end

hl.window_rule({
    match = { class = "^([Zz]oom)$", title = "^(annotate_toolbar)$" },
    no_initial_focus = true,
    suppress_event = "activate activatefocus",
})
rule("^(PulseUI)$", { center = true })
rule("^(pavucontrol)$", { center = true })

rule("^([Rr]ofi)$", { opacity = "0.95 0.8" })
rule("^(firefox)$", { opacity = "0.95 0.8" })
rule("^([Ee]macs)$", { opacity = "0.97 0.8" })
rule("^(dropdown)$", { opacity = "0.9 0.8" })

-- idle inhibit
rule("^(mpv|[Zz]oom|rpcs3|.*yuzu)$", { idle_inhibit = "focus" })
hl.window_rule({ match = { class = "^(firefox|floorp)$", title = "^(.*YouTube.*)$" }, idle_inhibit = "focus" })
hl.window_rule({ match = { title = "^([fF]oot)$" }, idle_inhibit = "focus" })

-- force focus on some floating window
rule("^(org.kde.polkit-kde-authentication-agent-1)$", { stay_focused = true, dim_around = true })
rule("^(gcr-prompter)$", { stay_focused = true, dim_around = true })
rule("^(Rofi)$", { stay_focused = true })

-- grimblast's selection overlay; it used to add this with `hyprctl keyword`,
-- which Hyprland >= 0.57 no longer has
hl.layer_rule({ match = { namespace = "^selection$" }, no_anim = true })
