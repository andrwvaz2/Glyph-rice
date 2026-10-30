local vars = require("variables")
local fn   = require("hyprland.functions")

hl.on("hyprland.start", function()
    -- Shell: тот, что выбран в rice
    hl.exec_cmd(vars.rice .. " start")

    -- во вложенной сессии системные демоны уже работают снаружи
    if vars.nested then return end

    -- DBus and systemd environment for portals (xdg-desktop-portal, pipewire, screencopy)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("test -x /usr/libexec/hyprpolkitagent && /usr/libexec/hyprpolkitagent || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider
    hl.exec_cmd("test -x /usr/libexec/geoclue-2.0/demos/agent && /usr/libexec/geoclue-2.0/demos/agent || /usr/lib/geoclue-2.0/demos/agent")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Bloq Num encendido en hardware y estado inicial
    hl.exec_cmd("sh -c 'echo 1 > \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/numlock_state\"; for dev in /sys/class/leds/*::numlock; do [ -e \"$dev\" ] && brightnessctl --device=\"${dev##*/}\" set 1 2>/dev/null || true; done'")

    -- hypridle поднимает шелл (Rules.idle): тайминги из house rules → ~/.config/demonshot/hypridle.conf

    -- фоновый kitty без окна: первый Super+Q тоже открывается мгновенно
    hl.exec_cmd(vars.terminal .. " --start-as=hidden")
end)

-- Resizer listener
hl.on("window.title", function(win)
    local d = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip = fn.move_actions(win) or {}

    fn.resizer(win, "Bitwarden", 20, 54, d, true)
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)

hl.on("window.open", function(win)
    local d = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip = fn.move_actions(win) or {}

    fn.resizer(win, "Bitwarden", 20, 54, d, true)
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)
