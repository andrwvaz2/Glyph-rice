local vars = require("variables")
local fn   = require("hyprland.functions")

-- глобалки шелла — shell:<имя>: их регистрирует тот шелл, что сейчас живой (demonshot, glyph), чего у него нет — молчит
-- Launcher: тап Super открывает на отпускании. Без interrupt-ов Super+1 тоже открыл бы лаунчер,
-- поэтому каждый Super+<key> не поглощая шлёт launcherInterrupt (bindin catchall сломан с 0.55)
hl.bind("SUPER + SUPER_L", hl.dsp.global("shell:launcher"), { release = true })
-- после Super+<key> release-бинд выше не срабатывает и interrupt залипает — сбрасываем на нажатии Super
hl.bind("SUPER_L", hl.dsp.global("shell:launcherArm"), { ignore_mods = true, non_consuming = true })
for _, key in ipairs({
    -- secondary modifiers: cover every Super+Mod+key combo
    "Control_L", "Control_R", "Shift_L", "Shift_R", "Alt_L", "Alt_R",
    -- workspaces
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    -- Super+<key> binds below
    "Q", "W", "E", "R", "T", "A", "D", "F", "G", "K", "L", "C", "V", "M", "N", "P", "B",
    "Z", "X", "U", "S", "H", "I", "space", "Escape",
    "Comma", "Period", "Minus", "Equal", "Backslash",
    "left", "right", "up", "down",
    "Page_Up", "Page_Down", "F12",
    "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277",
    "mouse_up", "mouse_down",
}) do
    hl.bind("SUPER + " .. key, hl.dsp.global("shell:launcherInterrupt"), { non_consuming = true })
end

-- Misc
hl.bind(vars.kbAltar, hl.dsp.global("shell:altar"))
hl.bind("SUPER + I", hl.dsp.global("shell:settings"))
hl.bind("SUPER + N", hl.dsp.global("shell:ward"))
hl.bind("SUPER + P", hl.dsp.global("shell:pact"))
hl.bind("SUPER + A", hl.dsp.global("shell:quick")) -- быстрые настройки glyph
hl.bind("SUPER + SHIFT + W", hl.dsp.global("shell:wall")) -- обои glyph
hl.bind(vars.kbSession, hl.dsp.global("shell:power"))
hl.bind(vars.kbPower, hl.dsp.global("shell:power"))
hl.bind(vars.kbLock, hl.dsp.exec_cmd(vars.lockCmd))
hl.bind(vars.kbRestoreLock, hl.dsp.exec_cmd(vars.lockCmd), { locked = true }) -- лок упал — поднять заново (сессия ещё заблокирована → нужен locked)

-- Brightness: ставит шелл (services/Backlight) — OSD двигается сразу, brightnessctl догоняет
hl.bind("XF86MonBrightnessUp", hl.dsp.global("shell:briUp"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("shell:briDown"), { locked = true, repeating = true })

-- Media
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Kill/restart
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd(vars.rice .. " kill"), { release = true })
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd(vars.rice .. " restart"), { release = true })

for i = 1, 5 do
    local key = tostring(i)
    hl.bind(vars.kbGoToWs .. " + " .. key, fn.wsaction("focus", "", i))
    hl.bind(vars.kbMoveWinToWs .. " + " .. key, fn.wsaction("move", "", i))
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })

-- Go to workspace group -1/+1
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })

-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- Window groups
hl.bind(vars.kbWindowGroupCycleNext, hl.dsp.window.cycle_next(), { repeating = true })
hl.bind(vars.kbWindowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), { repeating = true })
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), { repeating = true })
hl.bind(vars.kbToggleGroup, hl.dsp.group.toggle())
hl.bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.group.lock())

-- =========================================================
-- NIRI NAVIGATION & WINDOW ACTIONS (SCROLLING LAYOUT)
-- =========================================================

-- Focus Column / Window (Arrows + HJKL)
hl.bind("SUPER + left",  hl.dsp.layout("move -col"))
hl.bind("SUPER + right", hl.dsp.layout("move +col"))
hl.bind("SUPER + H",     hl.dsp.layout("move -col"))
hl.bind("SUPER + L",     hl.dsp.layout("move +col"))
hl.bind("SUPER + up",    hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down",  hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + K",     hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J",     hl.dsp.focus({ direction = "down" }))

-- Move Column Left / Right (Ctrl + Arrows/HJKL, and Shift + Arrows/HJKL)
hl.bind("CTRL + SUPER + left",   hl.dsp.layout("swapcol prev"))
hl.bind("CTRL + SUPER + right",  hl.dsp.layout("swapcol next"))
hl.bind("CTRL + SUPER + H",      hl.dsp.layout("swapcol prev"))
hl.bind("CTRL + SUPER + L",      hl.dsp.layout("swapcol next"))
hl.bind("SUPER + SHIFT + left",  hl.dsp.layout("swapcol prev"))
hl.bind("SUPER + SHIFT + right", hl.dsp.layout("swapcol next"))
hl.bind("SUPER + SHIFT + H",     hl.dsp.layout("swapcol prev"))
hl.bind("SUPER + SHIFT + L",     hl.dsp.layout("swapcol next"))

-- Move Window Up / Down inside column (Ctrl + Arrows/HJKL, and Shift + Arrows/HJKL)
hl.bind("CTRL + SUPER + up",     hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL + SUPER + down",   hl.dsp.window.move({ direction = "down" }))
hl.bind("CTRL + SUPER + K",      hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL + SUPER + J",      hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))

-- Focus Column First / Last
hl.bind("SUPER + Home", hl.dsp.layout("move tobeg"))
hl.bind("SUPER + End",  hl.dsp.layout("move toend"))

-- Column Sizing (Niri presets)
hl.bind("SUPER + R",         hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + SHIFT + R", hl.dsp.layout("colresize -conf"))
hl.bind("SUPER + Minus",     hl.dsp.layout("colresize -0.05"))
hl.bind("SUPER + Equal",     hl.dsp.layout("colresize +0.05"))

-- Maximize column, Fullscreen window, Center column
hl.bind("SUPER + F",         hl.dsp.layout("colresize fit"))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + M",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + C",         hl.dsp.layout("center"))

-- Consume & Expel (in / out of column)
hl.bind("SUPER + Comma",        hl.dsp.layout("consume"))
hl.bind("SUPER + Period",       hl.dsp.layout("expel"))
hl.bind("SUPER + BracketLeft",  hl.dsp.layout("consume"))
hl.bind("SUPER + BracketRight", hl.dsp.layout("expel"))

-- Terminal, Launcher & Close (Niri defaults)
hl.bind("SUPER + T",          hl.dsp.exec_cmd(vars.terminal))
hl.bind("SUPER + Return",     hl.dsp.exec_cmd(vars.terminal))
hl.bind("SUPER + D",          hl.dsp.global("shell:launcher"))
hl.bind("SUPER + Q",          hl.dsp.window.close())
hl.bind("ALT + F4",           hl.dsp.window.close())
hl.bind("SUPER + SHIFT + E",  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Mouse Wheel Column Scroll
hl.bind("SUPER + mouse_down",         hl.dsp.layout("move +col"))
hl.bind("SUPER + mouse_up",           hl.dsp.layout("move -col"))
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.layout("move +col"))
hl.bind("SUPER + SHIFT + mouse_up",   hl.dsp.layout("move -col"))

hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(vars.kbMoveWindow, hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.resize(), { mouse = true })
hl.bind(vars.kbResizeWindow, hl.dsp.window.resize(), { mouse = true })
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.center())
hl.bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
hl.bind(vars.kbPinWindow, hl.dsp.window.pin())

-- Special workspace toggles
hl.bind(vars.kbSpecialWs, fn.toggle_special("special"))
hl.bind(vars.kbSystemMonitorWs, fn.toggle_special("sysmon", "kitty --class btop -T btop btop"))
hl.bind(vars.kbMusicWs, fn.toggle_special("music", "spicetify watch -s"))
hl.bind(vars.kbCommunicationWs, fn.toggle_special("communication", "Telegram"))
hl.bind(vars.kbTodoWs, fn.toggle_special("todo", "flatpak run io.github.alainm23.planify"))

-- Apps
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))
hl.bind("SUPER + W",    hl.dsp.exec_cmd(vars.browser))
hl.bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor))
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd(vars.audioSettings))

-- Utilities
hl.bind("Print", hl.dsp.global("shell:shot"))
hl.bind("SUPER + SHIFT + S", hl.dsp.global("shell:shot"))
hl.bind("SUPER + ALT + R", fn.record(false, true))
hl.bind("CTRL + ALT + R", fn.record(false, false))
hl.bind("SUPER + SHIFT + ALT + R", fn.record(true, false))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("hyprctl kill"))
-- Volume
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+; canberra-gtk-play -i audio-volume-change -d 'volume' 2>/dev/null || true"
    ),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-; canberra-gtk-play -i audio-volume-change -d 'volume' 2>/dev/null || true"
    ),
    { locked = true, repeating = true }
)

-- Sleep
hl.bind("CTRL + SUPER + ALT + L", hl.dsp.exec_cmd(vars.sleepGestureCmd), { locked = true })

-- Clipboard & Charms
hl.bind("SUPER + SHIFT + V", hl.dsp.global("shell:clip"))
hl.bind("SUPER + ALT + Period", hl.dsp.global("shell:charms"))
hl.bind(
    "CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'),
    { locked = true }
)

-- Testing
hl.bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    )
)
