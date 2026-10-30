pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string soundsDir: Quickshell.env("HOME") + "/.local/share/sounds/NothingOS"

    Process { id: pNotify; command: ["pw-play", soundsDir + "/notifications/01_oi!.ogg"] }
    Process { id: pShot; command: ["pw-play", soundsDir + "/ui/screenshot.ogg"] }
    Process { id: pCharge; command: ["pw-play", soundsDir + "/ui/ChargingStarted.ogg"] }
    Process { id: pUnplug; command: ["pw-play", soundsDir + "/ui/Undock.ogg"] }
    Process { id: pBat; command: ["pw-play", soundsDir + "/ui/LowBattery.ogg"] }
    Process { id: pTick; command: ["pw-play", soundsDir + "/ui/Effect_Tick.ogg"] }

    function playNotification() {
        pNotify.running = false;
        pNotify.running = true;
    }

    function playShot() {
        pShot.running = false;
        pShot.running = true;
    }

    function playCharging() {
        pCharge.running = false;
        pCharge.running = true;
    }

    function playUnplug() {
        pUnplug.running = false;
        pUnplug.running = true;
    }

    function playLowBattery() {
        pBat.running = false;
        pBat.running = true;
    }

    function playTick() {
        pTick.running = false;
        pTick.running = true;
    }
}
