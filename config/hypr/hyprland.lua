-- Monitor config: Laptop (eDP-1) a la izquierda, Monitor externo a la derecha
hl.monitor({ output = "eDP-1", position = "0x0" })
hl.monitor({ output = "HDMI-A-1", position = "1920x0" })

-- XWayland масштабирует hypr: на HiDPI мыльно, зато размер верный при любом масштабе. Чётко на целом масштабе — в user.lua:
--   hl.config({ xwayland = { force_zero_scaling = true } }); hl.env("GDK_SCALE", "2")

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- свои бинды и правки поверх риса: hypr/user.lua (в .gitignore, обновления репо его не трогают)
local user = io.open(os.getenv("HOME") .. "/.config/hypr/user.lua")
if user then user:close(); require("user") end
