import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui

ColumnLayout {
    id: configPanel
    
    signal closeRequested()
    signal configSaved()

    property string pluginDir: ""
    
    property color foreground: Commons.Color.foreground
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
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Konfigurasi GlobalProtect"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.subtitle
            font.weight: Font.Bold
        }
    }

    // Portal
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Portal VPN"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.TextField {
            id: portalInput
            text: configPanel.portal
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
            Layout.minimumWidth: 0
        }
    }

    // Username
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Username (SSO BPS)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.TextField {
            id: usernameInput
            text: configPanel.username
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
            Layout.minimumWidth: 0
        }
    }

    // Browser
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Browser SAML (brave, firefox, chrome, default)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.TextField {
            id: browserInput
            text: configPanel.browser
            Layout.fillWidth: true
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
            Layout.minimumWidth: 0
        }
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Ui.Button {
            text: "Batal"
            Layout.fillWidth: true
            fontFamily: configPanel.fontFamily
            fontSize: Style.font.body
            foreground: configPanel.foreground
            focusable: true
            bordered: true
            onClicked: configPanel.closeRequested()
        }

        Ui.Button {
            text: "Simpan"
            Layout.fillWidth: true
            fontFamily: configPanel.fontFamily
            fontSize: Style.font.body
            foreground: configPanel.foreground
            focusable: true
            bordered: true
            onClicked: configPanel.saveConfig()
        }
    }
}
