local win = "MOD3"
local super = "SUPER"
local shift = "SHIFT"
local ctrl = "CTRL"

local function keys(...)
    return table.concat({ ... }, " + ")
end

local exec = hl.dsp.exec_cmd

-- launcher
hl.bind(keys(super, "i"), exec("firefox"))
-- hl.bind(keys(super, "i"), exec("floorp"))
hl.bind(keys(super, "e"), exec('emacsclient -c -a ""')) -- e for editor
hl.bind(keys(super, "c"), exec("kitty nvim")) -- c for code
-- hl.bind(keys(super, "return"), exec("rofi -show drun -theme ~/.config/rofi/styles/launcher.rasi"))
hl.bind(keys(super, "return"), exec("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window")) -- Main Menu (APP Launcher)

-- custom script
hl.bind(keys(super, "x"), exec("~/bin/kill_process"))
hl.bind(keys(super, "p"), exec("~/bin/passmenu"))
hl.bind(keys(super, "o"), exec("rofi -show window"))
hl.bind(keys(super, "v"), exec("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind(keys(super, "z"), exec("~/bin/power"))
hl.bind(keys(super, "s"), exec("~/bin/screenshot"))
hl.bind(keys(super, "r"), exec("~/bin/reload_module"))
hl.bind(keys(super, "n"), exec("swaync-client -t -sw"))

-- kill window
hl.bind(keys(super, "q"), exec("~/bin/smart_kill"))

-- change focus / move window
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    hl.bind(keys(super, key), hl.dsp.focus({ direction = direction }))
    hl.bind(keys(super, ctrl, key), hl.dsp.window.move({ direction = direction }))
end
hl.bind(keys(super, ctrl, "s"), hl.dsp.layout("togglesplit"))

-- fullscreen/monocle
hl.bind(keys(super, shift, "f"), hl.dsp.window.float({ action = "toggle" }))
hl.bind(keys(super, "f"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(keys(super, "m"), hl.dsp.window.fullscreen({ mode = "maximized" }))

-- last window
hl.bind(keys(ctrl, "Tab"), hl.dsp.focus({ urgent_or_last = true }))

-- Switch to workspace / move window to workspace using number row
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to key 0
    hl.bind(keys(super, key), hl.dsp.focus({ workspace = i, on_current_monitor = true }))
    hl.bind(keys(super, ctrl, key), hl.dsp.window.move({ workspace = i }))
end

-- media control
local locked = { locked = true }
hl.bind(keys(shift, ctrl, win, "m"), exec("~/bin/volume --toggle-mic"), locked)
hl.bind(keys(ctrl, win, "m"), exec("~/bin/volume --toggle"), locked)
hl.bind("XF86AudioMute", exec("~/bin/volume --toggle"), locked)
hl.bind(keys(shift, ctrl, win, "h"), exec("~/bin/volume --mic-dec"), locked)
hl.bind(keys(ctrl, win, "h"), exec("~/bin/volume --dec"), locked)
hl.bind("XF86AudioLowerVolume", exec("~/bin/volume --dec"), locked)
hl.bind(keys(shift, ctrl, win, "l"), exec("~/bin/volume --mic-inc"), locked)
hl.bind(keys(ctrl, win, "l"), exec("~/bin/volume --inc"), locked)
hl.bind("XF86AudioRaiseVolume", exec("~/bin/volume --inc"), locked)

-- brightness control
hl.bind(keys(ctrl, win, "k"), exec("~/bin/lightctl --inc"), { repeating = true })
hl.bind(keys(ctrl, win, "j"), exec("~/bin/lightctl --dec"), { repeating = true })

-- disable laptop monitor when lid is closed (switch name from 'hyprctl devices')
hl.bind("switch:Lid Switch", exec("hyprlock"), locked)
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false, mode = "preferred", position = "auto", scale = "auto" })
end, locked)
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
end, locked)

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(keys(super, "mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(keys(super, "mouse:273"), hl.dsp.window.resize(), { mouse = true })
