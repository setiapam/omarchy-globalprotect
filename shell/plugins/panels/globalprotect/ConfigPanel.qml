import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui

ColumnLayout {
    id: configPanel
    
    signal closeRequested()
    signal configSaved()

    property string pluginDir: ""
    
    property color foreground: Color.foreground
    property color dim: Qt.darker(foreground, 1.55)
    property string fontFamily: Style.font.family

    property string portal: "vpn.bps.go.id"
    property string username: "setia.pambudi"
    property string browser: "brave"

    spacing: Style.space(12)

    Component.onCompleted: loadConfig()

    Process {
        id: readProc
        command: ["bash", "-c", pluginDir + "/bin/omarchy-globalprotect-config read-all"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    let data = JSON.parse(text)
                    configPanel.portal = data.portal || "vpn.bps.go.id"
                    configPanel.username = data.username || "setia.pambudi"
                    configPanel.browser = data.browser || "brave"
                } catch(e) {}
            }
        }
    }

    Process {
        id: saveProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                configPanel.configSaved()
                configPanel.closeRequested()
            }
        }
    }

    function loadConfig() {
        if (!readProc.running) readProc.running = true
    }

    function saveConfig() {
        if (saveProc.running) return
        saveProc.command = [
            "bash", "-c",
            pluginDir + "/bin/omarchy-globalprotect-config write '" + portalInput.text + "' '" + usernameInput.text + "' '" + browserInput.text + "'"
        ]
        saveProc.running = true
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Konfigurasi GlobalProtect"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("sm")
            font.weight: Font.Bold
            Layout.fillWidth: true
        }
    }

    // Portal
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            text: "Portal VPN"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
        }
        TextField {
            id: portalInput
            text: configPanel.portal
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: configPanel.dim
                radius: 4
            }
        }
    }

    // Username
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            text: "Username (SSO BPS)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
        }
        TextField {
            id: usernameInput
            text: configPanel.username
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: configPanel.dim
                radius: 4
            }
        }
    }

    // Browser
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            text: "Browser SAML (brave, firefox, chrome, default)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
        }
        TextField {
            id: browserInput
            text: configPanel.browser
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize("xs")
            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: configPanel.dim
                radius: 4
            }
        }
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Button {
            text: "Batal"
            Layout.fillWidth: true
            onClicked: configPanel.closeRequested()
        }

        Button {
            text: "Simpan"
            Layout.fillWidth: true
            onClicked: configPanel.saveConfig()
        }
    }
}
