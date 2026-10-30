import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings

// barra superior horizontal: cápsula elegante en el borde superior.
// Izquierda: launcher (marca), escritorios y título de ventana activa.
// Centro: reloj digital y fecha.
// Derecha: bandeja del sistema (idioma, red, bt, audio, dnd, batería, modos y apagado).
PanelWindow {
    id: root

    signal markClicked
    signal trayClicked
    signal powerClicked
    signal clockClicked

    anchors { top: true; left: true; right: true }
    implicitHeight: Math.ceil(52 * Theme.s)
    color: "transparent"
    WlrLayershell.namespace: "glyph-bar"

    readonly property int active: {
        const id = Hyprland.focusedWorkspace?.id ?? 1;
        return ((id - 1) % 5) + 1;
    }
    readonly property int count: 5
    readonly property var top: ToplevelManager.activeToplevel
    readonly property var bat: UPower.displayDevice
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    // hyprland 0.56 con lua: dispatch acepta expresión lua
    function go(ws) { Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Estado del menú contextual para apps en segundo plano
    property var activeTrayItem: null
    property var activeTrayTl: null
    property string activeTrayName: ""
    property string activeTrayGlyph: ""
    property bool trayMenuOpen: false

    function closeTrayApp(item, tl) {
        if (tl && typeof tl.close === "function") tl.close();
        if (item) {
            const id = (item.id || item.title || "").toLowerCase();
            if (id.includes("discord") || id.includes("vesktop")) {
                Quickshell.execDetached(["flatpak", "kill", "com.discordapp.Discord"]);
                Quickshell.execDetached(["pkill", "-f", "Discord"]);
            } else if (id.includes("zapfast") || id.includes("whatsapp")) {
                Quickshell.execDetached(["pkill", "-f", "zapfast"]);
            } else if (id.includes("telegram")) {
                Quickshell.execDetached(["pkill", "-f", "telegram-desktop"]);
                Quickshell.execDetached(["pkill", "-f", "Telegram"]);
            } else if (id.includes("spotify")) {
                Quickshell.execDetached(["pkill", "-f", "spotify"]);
            } else if (id.includes("steam")) {
                Quickshell.execDetached(["pkill", "-f", "steam"]);
            } else if (id.includes("youtube") || id.includes("music")) {
                Quickshell.execDetached(["pkill", "-f", "youtube-music"]);
            } else {
                const base = (item.id || "").split("_")[0];
                if (base) Quickshell.execDetached(["pkill", "-f", base]);
            }
        }
        root.trayMenuOpen = false;
        root.activeTrayItem = null;
        root.activeTrayTl = null;
    }

    // Mapeo de iconos Glyph para aplicaciones activas
    readonly property var glyphMap: [
        ["discord", "\u{F066F}"],
        ["vesktop", "\u{F066F}"],
        ["equibop", "\u{F066F}"],
        ["webcord", "\u{F066F}"],
        ["armcord", "\u{F066F}"],
        ["disc", "\u{F066F}"],
        ["zapfast", "\u{F232}"],
        ["whatsapp", "\u{F232}"],
        ["zap", "\u{F232}"],
        ["telegram", "\u{F2C6}"],
        ["tg", "\u{F2C6}"],
        ["zen", "\u{F0239}"],
        ["firefox", "\u{F0239}"],
        ["chrome", "\u{F059F}"],
        ["chrom", "\u{F059F}"],
        ["brave", "\u{F059F}"],
        ["kitty", "\u{F018D}"],
        ["foot", "\u{F018D}"],
        ["alacritty", "\u{F018D}"],
        ["terminal", "\u{F018D}"],
        ["ptyxis", "\u{F018D}"],
        ["code", "\u{F0A1E}"],
        ["codium", "\u{F0A1E}"],
        ["zed", "\u{F0A1E}"],
        ["spotify", "\u{F04C7}"],
        ["spot", "\u{F04C7}"],
        ["steam", "\u{F04D3}"],
        ["slack", "\u{F04B1}"],
        ["nautilus", "\u{F024B}"],
        ["thunar", "\u{F024B}"],
        ["files", "\u{F024B}"],
        ["papers", "\u{F01DA}"],
        ["zathura", "\u{F01DA}"],
        ["pdf", "\u{F01DA}"],
        ["gimp", "\u{F02E9}"],
        ["inkscape", "\u{F02E9}"],
        ["obsidian", "\u{F082E}"],
        ["btop", "\u{F035B}"],
        ["software", "\u{F018B}"],
        ["settings", "\u{F0493}"],
        ["pavucontrol", "\u{F057E}"],
        ["mpv", "\u{F040A}"],
        ["vlc", "\u{F040A}"]
    ]

    function getAppGlyph(appId, title) {
        const text = `${appId || ""} ${title || ""}`.toLowerCase();
        for (let i = 0; i < glyphMap.length; i++) {
            if (text.includes(glyphMap[i][0])) {
                return glyphMap[i][1];
            }
        }
        return "\u{F07D4}";
    }

    Stage {
        Rectangle {
            id: pill
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 14
                rightMargin: 14
                topMargin: 6
                bottomMargin: 6
            }
            radius: height / 2
            color: Theme.s1
            border { width: 1; color: Theme.s2 }

            WheelHandler { onWheel: e => root.go(e.angleDelta.y > 0 ? "-1" : "+1") }

            // --- SECCIÓN IZQUIERDA: Marca/Launcher, Escritorios y Título ---
            Row {
                id: leftSection
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                // Marca / Launcher: anillo de 16 puntos
                Item {
                    id: mark
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    Ring { anchors.fill: parent; n: 16; dot: 3 }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: Sys.live ? Theme.red : Theme.fg
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.markClicked() }
                }

                // Escritorios (1 al 5 en horizontal)
                Row {
                    id: ws
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: root.count

                        Rectangle {
                            id: wsBtn
                            required property int index
                            readonly property int n: index + 1
                            readonly property bool occ: (Hyprland.workspaces.values.find(w => w.id === n)?.toplevels.values.length ?? 0) > 0
                            readonly property bool on: root.active === n
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            width: on ? 26 : 10
                            height: on ? 26 : 10
                            radius: on ? 13 : 5
                            color: on ? "transparent" : Theme.red
                            border.width: on ? 2 : 0
                            border.color: Theme.red
                            opacity: on || occ ? 1.0 : 0.45

                            Text {
                                anchors.centerIn: parent
                                text: wsBtn.n
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.fg
                                visible: wsBtn.on
                            }

                            Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on height { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on radius { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            Behavior on opacity { NumberAnimation { duration: Theme.t } }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.go(wsBtn.n) }
                        }
                    }
                }

                // Separador sutil entre escritorios y aplicaciones
                Rectangle {
                    visible: ToplevelManager.toplevels.values.filter(tl => !tl.minimized).length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Theme.s2
                }

                // Apps activas en modo Glyph
                Row {
                    id: appsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: ToplevelManager.toplevels.values.filter(tl => !tl.minimized)

                        Rectangle {
                            id: appItem
                            required property var modelData
                            readonly property var tl: modelData
                            readonly property bool isFocused: tl.activated ?? false
                            readonly property string glyphIcon: root.getAppGlyph(tl.appId, tl.title)

                            width: 26
                            height: 26
                            radius: 13
                            color: isFocused ? Theme.s2 : appHov.hovered ? Theme.s2 : "transparent"
                            border { width: isFocused ? 1 : 0; color: Theme.red }

                            Behavior on color { ColorAnimation { duration: Theme.t } }

                            Icon {
                                anchors.centerIn: parent
                                text: appItem.glyphIcon
                                font.pixelSize: 14
                                color: appItem.isFocused ? Theme.red : appHov.hovered ? Theme.fg : Theme.grey
                            }

                            // Punto rojo debajo de la app enfocada
                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 2
                                }
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Theme.red
                                visible: appItem.isFocused
                            }

                            HoverHandler { id: appHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (typeof appItem.tl.activate === "function") {
                                        appItem.tl.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- REPRODUCTOR DE MEDIOS ---
            Rectangle {
                id: mediaWidget
                visible: !!Media.player && !!Media.player.trackTitle
                anchors {
                    right: clk.left
                    rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                height: 32
                width: mediaContent.implicitWidth + 20
                radius: 16
                color: Theme.s2
                border { width: 1; color: Theme.s3 }

                WheelHandler {
                    onWheel: e => {
                        if (e.angleDelta.y > 0) Media.player?.next();
                        else Media.player?.previous();
                    }
                }

                Row {
                    id: mediaContent
                    anchors.centerIn: parent
                    spacing: 10

                    // Zona clickeable para abrir el submenú: Carátula + Texto
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Matriz de puntos como ecualizador
                        Item {
                            id: eqMatrix
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter

                            property var levels: [1, 2, 3, 1]
                            Timer {
                                running: Media.playing
                                interval: 110
                                repeat: true
                                onTriggered: {
                                    eqMatrix.levels = [
                                        Math.floor(Math.random() * 4) + 1,
                                        Math.floor(Math.random() * 4) + 1,
                                        Math.floor(Math.random() * 4) + 1,
                                        Math.floor(Math.random() * 4) + 1
                                    ];
                                }
                                onRunningChanged: if (!running) eqMatrix.levels = [1, 1, 1, 1]
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 2

                                Repeater {
                                    model: 4
                                    Column {
                                        id: eqCol
                                        required property int index
                                        spacing: 2
                                        anchors.bottom: parent.bottom

                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                readonly property int dotLevel: 4 - index
                                                readonly property bool lit: dotLevel <= eqMatrix.levels[eqCol.index]
                                                width: 3
                                                height: 3
                                                radius: 1.5
                                                color: lit ? Theme.red : Theme.s3
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Título y Artista
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            width: Math.min(180, Math.max(mediaTitle.implicitWidth, mediaArtist.implicitWidth))

                            Text {
                                id: mediaTitle
                                width: parent.width
                                text: Media.player?.trackTitle || ""
                                font.family: Theme.ui
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.fg
                                elide: Text.ElideRight
                            }
                            Text {
                                id: mediaArtist
                                width: parent.width
                                text: Media.player?.trackArtist || ""
                                font.family: Theme.ui
                                font.pixelSize: 10
                                color: Theme.grey
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.mediaOpen = !root.mediaOpen }
                    }

                    // Controles compactos
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        // Anterior
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F04AE}"
                            font.pixelSize: 13
                            color: Media.player?.canGoPrevious ? Theme.fg : Theme.mute
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.previous() }
                        }

                        // Play / Pause con botón rojo
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: Theme.red

                            Icon {
                                anchors.centerIn: parent
                                text: Media.playing ? "\u{F03E4}" : "\u{F040A}"
                                font.pixelSize: 10
                                color: "#FFFFFF"
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.togglePlaying() }
                        }

                        // Siguiente
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F04AD}"
                            font.pixelSize: 13
                            color: Media.player?.canGoNext ? Theme.fg : Theme.mute
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.next() }
                        }
                    }
                }
            }

            // --- SECCIÓN CENTRO: Reloj y Fecha ---
            Row {
                id: clk
                anchors.centerIn: parent
                spacing: 8
                TapHandler { onTapped: root.clockClicked() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }

                Num {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.hh(clock.date)
                    font.pixelSize: 18
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.red
                }
                Num {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.date, "mm")
                    font.pixelSize: 18
                }
                Lb {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 4
                    text: Qt.locale("en_US").toString(clock.date, "ddd d")
                    px: 11
                    color: Theme.grey
                }
            }

            // --- SECCIÓN DERECHA: Bandeja, Batería, Modos y Apagado ---
            Row {
                id: rightSection
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                // Apps minimizadas / Tray en modo Glyph (Discord, ZapFast, etc.)
                Row {
                    id: minimizedTrayRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    visible: SystemTray.items.values.length > 0 || minWins.length > 0

                    readonly property var minWins: ToplevelManager.toplevels.values.filter(tl => tl.minimized && !SystemTray.items.values.some(s => (s.id && tl.appId && (s.id.toLowerCase().includes(tl.appId.toLowerCase()) || tl.appId.toLowerCase().includes(s.id.toLowerCase())))))

                    // Iconos del System Tray (Discord, ZapFast, Telegram, etc.)
                    Repeater {
                        model: SystemTray.items.values

                        Rectangle {
                            id: trayBtn
                            required property var modelData
                            readonly property var item: modelData
                            readonly property string glyph: root.getAppGlyph(item.id, item.title)

                            width: 26
                            height: 26
                            radius: 13
                            color: trayHov.hovered ? Theme.s2 : "transparent"
                            border { width: 1; color: trayHov.hovered ? Theme.s3 : "transparent" }

                            Icon {
                                anchors.centerIn: parent
                                text: trayBtn.glyph
                                font.pixelSize: 13
                                color: trayHov.hovered ? Theme.fg : Theme.grey
                            }

                            // Punto tenue indicador de minimizado / background
                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 2
                                }
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Theme.grey
                                opacity: 0.6
                            }

                            HoverHandler { id: trayHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    const id = (trayBtn.item.id || trayBtn.item.title || "").toLowerCase();
                                    if (id.includes("youtube") || id.includes("music")) {
                                        Quickshell.execDetached(["youtube-music"]);
                                    } else if (typeof trayBtn.item.activate === "function") {
                                        trayBtn.item.activate(0, 0);
                                    }
                                }
                            }
                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: {
                                    if (root.trayMenuOpen && root.activeTrayItem === trayBtn.item) {
                                        root.trayMenuOpen = false;
                                    } else {
                                        root.activeTrayItem = trayBtn.item;
                                        root.activeTrayTl = null;
                                        root.activeTrayName = (trayBtn.item.title || trayBtn.item.id || "App").split("_")[0];
                                        root.activeTrayGlyph = trayBtn.glyph;
                                        root.trayMenuOpen = true;
                                    }
                                }
                            }
                            TapHandler {
                                acceptedButtons: Qt.MiddleButton
                                onTapped: {
                                    root.closeTrayApp(trayBtn.item, null);
                                }
                            }
                        }
                    }

                    // Ventanas minimizadas (si no están en el tray)
                    Repeater {
                        model: minimizedTrayRow.minWins

                        Rectangle {
                            id: minWinBtn
                            required property var modelData
                            readonly property var tl: modelData
                            readonly property string glyph: root.getAppGlyph(tl.appId, tl.title)

                            width: 26
                            height: 26
                            radius: 13
                            color: minHov.hovered ? Theme.s2 : "transparent"
                            border { width: 1; color: minHov.hovered ? Theme.s3 : "transparent" }

                            Icon {
                                anchors.centerIn: parent
                                text: minWinBtn.glyph
                                font.pixelSize: 13
                                color: minHov.hovered ? Theme.fg : Theme.grey
                            }

                            // Barra tenue indicando minimizado
                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 2
                                }
                                width: 6
                                height: 2
                                radius: 1
                                color: Theme.grey
                                opacity: 0.5
                            }

                            HoverHandler { id: minHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (typeof minWinBtn.tl.activate === "function") {
                                        minWinBtn.tl.activate();
                                    }
                                }
                            }
                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: {
                                    if (root.trayMenuOpen && root.activeTrayTl === minWinBtn.tl) {
                                        root.trayMenuOpen = false;
                                    } else {
                                        root.activeTrayItem = null;
                                        root.activeTrayTl = minWinBtn.tl;
                                        root.activeTrayName = minWinBtn.tl.title || minWinBtn.tl.appId || "Ventana";
                                        root.activeTrayGlyph = minWinBtn.glyph;
                                        root.trayMenuOpen = true;
                                    }
                                }
                            }
                            TapHandler {
                                acceptedButtons: Qt.MiddleButton
                                onTapped: {
                                    root.closeTrayApp(null, minWinBtn.tl);
                                }
                            }
                        }
                    }
                }

                // Separador sutil si hay apps en el tray/minimizadas
                Rectangle {
                    visible: minimizedTrayRow.visible
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Theme.s2
                }

                // Distribución de teclado
                Lb {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.layout
                    px: 11
                    color: Theme.fg
                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // WiFi
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                    color: root.wifi?.connected ? Theme.fg : Theme.grey
                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // Bluetooth
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Bluetooth.defaultAdapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                    color: Bluetooth.devices.values.some(d => d.connected) ? Theme.fg : Theme.grey
                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // Volumen
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.muted ? "\u{F075F}" : "\u{F057E}"
                    color: Theme.fg
                    WheelHandler { onWheel: e => Sys.setVol(Sys.vol + (e.angleDelta.y > 0 ? 0.05 : -0.05)) }
                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // No molestar / Notificaciones
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.state.dnd ? "\u{F009B}" : "\u{F009A}"
                    color: Notes.list.length ? Theme.fg : Theme.grey
                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // Batería en horizontal
                Row {
                    id: batc
                    visible: root.bat.isLaptopBattery
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    HoverHandler { id: batHov }

                    readonly property bool ac: !UPower.onBattery
                    readonly property bool charging: root.bat.state === UPowerDeviceState.Charging
                    readonly property bool low: !ac && root.bat.percentage < 0.15
                    property real pulse: 1
                    SequentialAnimation on pulse {
                        running: batc.charging
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) batc.pulse = 1
                        NumberAnimation { to: 0.35; duration: 1100; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
                    }

                    Icon {
                        visible: batc.ac
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F140B}"
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 13
                        radius: 4
                        color: "transparent"
                        border { width: 1.2; color: Theme.grey }

                        Rectangle {
                            x: 2
                            y: 2
                            width: Math.max(2, (parent.width - 4) * root.bat.percentage)
                            height: parent.height - 4
                            radius: 2
                            color: batc.low ? Theme.red : Theme.fg
                            opacity: batc.pulse
                        }
                    }

                    Lb {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Math.round(root.bat.percentage * 100)}%`
                        px: 11
                    }

                    TapHandler { onTapped: root.trayClicked() }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                // Ticks de modo de energía
                Item {
                    id: ticks
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 18

                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: Rules.modeCount
                            Rectangle {
                                required property int index
                                anchors.bottom: parent.bottom
                                width: 3
                                height: 5 + index * 3
                                radius: 1.5
                                color: index <= Rules.mode ? Theme.fg : Theme.s3
                            }
                        }
                    }
                    HoverHandler { id: tickHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Rules.setMode((Rules.mode + 1) % Rules.modeCount) }
                }

                // Botón de Apagado
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0425}"
                    color: pwr.hovered ? Theme.fg : Theme.grey
                    font.pixelSize: 16
                    HoverHandler { id: pwr; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.powerClicked() }
                }
            }
        }
    }

    // ---- Popover de batería y energía (se despliega hacia abajo desde la barra superior) ----
    readonly property bool powHot: batHov.hovered || tickHov.hovered || popHov.hovered
    property bool powOpen: false
    property int powPeek: -1
    onPowHotChanged: powHot ? powOpenT.restart() : powCloseT.restart()
    Timer { id: powOpenT; interval: 180; onTriggered: if (root.powHot) root.powOpen = true }
    Timer { id: powCloseT; interval: 300; onTriggered: if (!root.powHot) root.powOpen = false }
    function hm(sec) { const m = Math.round(sec / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} m` : `${m} m`; }
    readonly property string batState: root.bat.state === UPowerDeviceState.Charging
        ? "charging" + (root.bat.timeToFull ? ` · full in ${hm(root.bat.timeToFull)}` : "")
        : !UPower.onBattery ? "on ac · full"
        : "on battery" + (root.bat.timeToEmpty ? ` · ${hm(root.bat.timeToEmpty)} left` : "")

    PopupWindow {
        id: pop
        property real t: root.powOpen ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        visible: t > 0
        // Abre debajo de los ticks de la barra superior
        anchor.item: ticks
        anchor.rect: Qt.rect(-200, ticks.height + 14, 1, 1)
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        implicitWidth: Math.ceil(440 * Theme.s)
        implicitHeight: Math.ceil(card.height * Theme.s)
        color: "transparent"

        Stage {
            Rectangle {
                id: card
                width: 440
                height: body.height + 52
                radius: 36
                color: Theme.s1
                border { width: 1; color: Theme.s2 }
                opacity: pop.t
                transform: Translate { y: -16 * (1 - pop.t) }
                HoverHandler { id: popHov }

                Column {
                    id: body
                    x: 26
                    y: 26
                    width: parent.width - 52
                    spacing: 18

                    Row {
                        spacing: 14
                        Num { text: Math.round(root.bat.percentage * 100); font.pixelSize: 72 }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Lb { text: "% battery"; color: Theme.fg }
                            Lb { text: root.batState }
                        }
                    }
                    Seg { width: parent.width; height: 6; n: 24; f: root.bat.percentage; on: batc.low ? Theme.red : Theme.fg }

                    Lb { topPadding: 6; text: "power mode" }
                    Row {
                        spacing: (body.width - Rules.modeCount * 80) / Math.max(1, Rules.modeCount - 1)
                        Repeater {
                            model: Rules.modeCount
                            Column {
                                id: mo
                                required property int index
                                readonly property bool on: Rules.mode === index
                                spacing: 10
                                Rectangle {
                                    width: 80
                                    height: 80
                                    radius: 40
                                    color: mo.on ? Theme.fg : moHov.hovered ? Theme.s3 : Theme.s2
                                    Behavior on color { ColorAnimation { duration: Theme.t } }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                anchors.bottom: parent.bottom
                                                width: 5
                                                height: 8 + index * 6
                                                radius: 2.5
                                                color: index <= mo.index ? (mo.on ? Theme.ink : Theme.fg) : (mo.on ? Theme.mute : Theme.s3)
                                            }
                                        }
                                    }
                                    HoverHandler {
                                        id: moHov
                                        cursorShape: Qt.PointingHandCursor
                                        onHoveredChanged: if (hovered) root.powPeek = mo.index; else if (root.powPeek === mo.index) root.powPeek = -1
                                    }
                                    TapHandler { onTapped: Rules.setMode(mo.index) }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: mo.index === 3 ? "max" : Rules.modes[mo.index].name; color: mo.on ? Theme.fg : Theme.grey }
                            }
                        }
                    }
                    Lb {
                        readonly property int i: root.powPeek >= 0 ? root.powPeek : Rules.mode
                        width: parent.width
                        elide: Text.ElideRight
                        text: `${Rules.modes[i].what} · ${i === 0 ? Rules.rates[0] : Rules.refreshHz} hz`
                    }
                }
            }
        }
    }

    // ---- Popover / Submenú completo del reproductor de medios ----
    property bool mediaOpen: false

    PopupWindow {
        id: mediaPop
        property real t: root.mediaOpen && !!Media.player ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        visible: t > 0
        anchor.item: mediaWidget
        anchor.rect: Qt.rect(-80, mediaWidget.height + 12, 1, 1)
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        implicitWidth: Math.ceil(360 * Theme.s)
        implicitHeight: Math.ceil(mediaCard.height * Theme.s)
        color: "transparent"

        Stage {
            Rectangle {
                id: mediaCard
                width: 360
                height: mediaBody.height + 44
                radius: 32
                color: Theme.s1
                border { width: 1; color: Theme.s2 }
                opacity: mediaPop.t
                transform: Translate { y: -16 * (1 - mediaPop.t) }

                Column {
                    id: mediaBody
                    x: 22
                    y: 22
                    width: parent.width - 44
                    spacing: 16

                    // Encabezado
                    Item {
                        width: parent.width
                        height: 20

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F040A}"
                                font.pixelSize: 13
                                color: Theme.red
                            }
                            Lb {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Media.player?.identity ?? "Media"
                                color: Theme.grey
                                px: 11
                            }
                        }

                        Icon {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: "\u{F0156}"
                            font.pixelSize: 14
                            color: Theme.grey
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.mediaOpen = false }
                        }
                    }

                    // Ecualizador y Detalles
                    Row {
                        width: parent.width
                        spacing: 16

                        // Matriz de puntos como ecualizador ampliado
                        Rectangle {
                            id: bigEq
                            width: 68
                            height: 68
                            radius: 20
                            color: Theme.s2
                            border { width: 1; color: Theme.s3 }
                            anchors.verticalCenter: parent.verticalCenter

                            property var levels: [2, 4, 6, 3, 5, 2, 4]
                            Timer {
                                running: root.mediaOpen && Media.playing
                                interval: 110
                                repeat: true
                                onTriggered: {
                                    bigEq.levels = [
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1,
                                        Math.floor(Math.random() * 6) + 1
                                    ];
                                }
                                onRunningChanged: if (!running) bigEq.levels = [1, 2, 2, 2, 2, 2, 1]
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: 7
                                    Column {
                                        id: bCol
                                        required property int index
                                        spacing: 3
                                        anchors.bottom: parent.bottom

                                        Repeater {
                                            model: 6
                                            Rectangle {
                                                required property int index
                                                readonly property int dotLevel: 6 - index
                                                readonly property bool lit: dotLevel <= bigEq.levels[bCol.index]
                                                width: 4
                                                height: 4
                                                radius: 2
                                                color: lit ? Theme.red : Theme.s3
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - bigEq.width - 16
                            spacing: 4

                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: Media.player?.trackTitle || "Nada reproduciéndose"
                                font { family: Theme.ui; pixelSize: 15; weight: Font.DemiBold }
                                color: Theme.fg
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Media.player?.trackArtist || ""
                                font { family: Theme.ui; pixelSize: 12 }
                                color: Theme.grey
                            }
                        }
                    }

                    // Barra de progreso interactiva (con Seg de Glyph)
                    Column {
                        width: parent.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 12

                            Seg {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 6
                                n: 24
                                f: Media.player?.lengthSupported && Media.player.length > 0 ? Media.position / Media.player.length : 0
                                on: Theme.red
                                off: Theme.s3
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (Media.player?.lengthSupported && Media.player.length > 0) {
                                        Media.player.position = (mouse.x / width) * Media.player.length;
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 14
                            Lb { anchors.left: parent.left; text: Media.time(Media.position); px: 10 }
                            Lb {
                                anchors.right: parent.right
                                visible: !!Media.player?.lengthSupported
                                text: Media.time(Media.player?.length)
                                px: 10
                            }
                        }
                    }

                    // Controles principales
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 24

                        // Anterior
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F04AE}"
                            font.pixelSize: 22
                            color: Media.player?.canGoPrevious ? Theme.fg : Theme.mute
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.previous() }
                        }

                        // Play / Pause circular destacado en rojo
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 46
                            height: 46
                            radius: 23
                            color: Theme.red

                            Icon {
                                anchors.centerIn: parent
                                text: Media.playing ? "\u{F03E4}" : "\u{F040A}"
                                font.pixelSize: 18
                                color: "#FFFFFF"
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.togglePlaying() }
                        }

                        // Siguiente
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F04AD}"
                            font.pixelSize: 22
                            color: Media.player?.canGoNext ? Theme.fg : Theme.mute
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Media.player?.next() }
                        }
                    }
                }
            }
        }
    }

    // --- POPUP: MENÚ CONTEXTUAL DE APLICACIÓN EN SEGUNDO PLANO / BANDEJA ---
    PopupWindow {
        id: trayMenuPop
        property real t: root.trayMenuOpen && (root.activeTrayItem !== null || root.activeTrayTl !== null) ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        visible: t > 0
        anchor.item: minimizedTrayRow
        anchor.rect: Qt.rect(-60, minimizedTrayRow.height + 10, 1, 1)
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        implicitWidth: Math.ceil(210 * Theme.s)
        implicitHeight: Math.ceil(trayMenuCard.height * Theme.s)
        color: "transparent"

        Stage {
            Rectangle {
                id: trayMenuCard
                width: 210
                height: trayMenuCol.height + 24
                radius: 18
                color: Theme.s1
                border { width: 1; color: Theme.s2 }
                opacity: trayMenuPop.t
                transform: Translate { y: -10 * (1 - trayMenuPop.t) }

                Timer {
                    id: trayAutoClose
                    interval: 4500
                    running: root.trayMenuOpen && !cardHov.hovered
                    onTriggered: root.trayMenuOpen = false
                }
                HoverHandler { id: cardHov }

                Column {
                    id: trayMenuCol
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 8

                    // Cabecera: icono y nombre
                    Row {
                        width: parent.width
                        spacing: 8

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.activeTrayGlyph
                            font.pixelSize: 16
                            color: Theme.red
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 26
                            text: root.activeTrayName.toUpperCase()
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.fg
                            elide: Text.ElideRight
                        }
                    }

                    // Línea divisoria
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.s2
                    }

                    // Opción: Abrir
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: openHov.hovered ? Theme.s2 : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F03E0}"
                                font.pixelSize: 14
                                color: Theme.fg
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Abrir"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                color: Theme.fg
                            }
                        }

                        HoverHandler { id: openHov; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (root.activeTrayTl) {
                                    if (typeof root.activeTrayTl.activate === "function") root.activeTrayTl.activate();
                                } else if (root.activeTrayItem) {
                                    const id = (root.activeTrayItem.id || root.activeTrayItem.title || "").toLowerCase();
                                    if (id.includes("youtube") || id.includes("music")) {
                                        Quickshell.execDetached(["youtube-music"]);
                                    } else if (typeof root.activeTrayItem.activate === "function") {
                                        root.activeTrayItem.activate(0, 0);
                                    }
                                }
                                root.trayMenuOpen = false;
                            }
                        }
                    }

                    // Opción: Cerrar aplicación
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: closeHov.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F0156}"
                                font.pixelSize: 14
                                color: Theme.red
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Cerrar aplicación"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.red
                            }
                        }

                        HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                root.closeTrayApp(root.activeTrayItem, root.activeTrayTl);
                            }
                        }
                    }
                }
            }
        }
    }
}
