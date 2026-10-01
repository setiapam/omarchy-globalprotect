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

    // Form Properties
    property string portal: ""
    property string gateway: ""
    property bool isSaml: true
    property string username: ""
    property string password: ""
    property string browser: "default"
    property bool ignoreTls: false
    property bool fixOpenssl: false
    property bool noDtls: false

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
                    configPanel.portal = data.portal || ""
                    configPanel.gateway = data.gateway || ""
                    configPanel.isSaml = (data.saml !== undefined) ? data.saml : true
                    configPanel.username = data.username || ""
                    configPanel.password = data.password || ""
                    configPanel.browser = data.browser || "default"
                    configPanel.ignoreTls = data.ignoreTlsErrors || false
                    configPanel.fixOpenssl = data.fixOpenssl || false
                    configPanel.noDtls = data.noDtls || false
                } catch (e) {
                    console.warn("GlobalProtect: Failed to parse config JSON:", e)
                }
            }
        }
    }

    Process {
        id: saveProc
        command: [
            pluginDir + "/bin/omarchy-globalprotect-config",
            "write-all",
            portalInput.text.trim(),
            gwInput.text.trim(),
            userInput.text.trim(),
            passInput.text,
            samlSwitch.checked ? "true" : "false",
            browserInput.text.trim(),
            tlsSwitch.checked ? "true" : "false",
            opensslSwitch.checked ? "true" : "false",
            dtlsSwitch.checked ? "true" : "false"
        ]
        onExited: {
            notifyProc.running = true
            configPanel.configSaved()
            configPanel.closeRequested()
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-a", "GlobalProtect", "-i", "network-vpn", "Configuration Saved", "GlobalProtect settings updated successfully."]
    }

    function loadConfig() { readProc.running = true }
    function saveConfig() { saveProc.running = true }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Style.space(4)

        Text {
            text: "Settings"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(14)
            font.weight: Font.DemiBold
            color: configPanel.foreground
        }

        Item { Layout.fillWidth: true }

        Button {
            text: "✕"
            onClicked: configPanel.closeRequested()
        }
    }

    // Portal Server
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)

        Text {
            text: "Portal Server"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(10)
            color: configPanel.dim
        }

        TextField {
            id: portalInput
            Layout.fillWidth: true
            text: configPanel.portal
            placeholderText: "vpn.bps.go.id"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
        }
    }

    // Gateway (Optional)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)

        Text {
            text: "Gateway (Optional)"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(10)
            color: configPanel.dim
        }

        TextField {
            id: gwInput
            Layout.fillWidth: true
            text: configPanel.gateway
            placeholderText: "Leave blank to match portal"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
        }
    }

    // SAML SSO Toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Text {
            text: "Use SAML / SSO Login"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
            color: configPanel.foreground
            Layout.fillWidth: true
        }

        Switch {
            id: samlSwitch
            checked: configPanel.isSaml
        }
    }

    // Username
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)

        Text {
            text: "Username"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(10)
            color: configPanel.dim
        }

        TextField {
            id: userInput
            Layout.fillWidth: true
            text: configPanel.username
            placeholderText: "setia.pambudi"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
        }
    }

    // Password (only shown if SAML is false)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)
        visible: !samlSwitch.checked

        Text {
            text: "Password"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(10)
            color: configPanel.dim
        }

        TextField {
            id: passInput
            Layout.fillWidth: true
            text: configPanel.password
            echoMode: TextInput.Password
            placeholderText: "••••••••"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
        }
    }

    // SSO Browser
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)
        visible: samlSwitch.checked

        Text {
            text: "SSO Browser"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(10)
            color: configPanel.dim
        }

        TextField {
            id: browserInput
            Layout.fillWidth: true
            text: configPanel.browser
            placeholderText: "default (or remote, brave, firefox)"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(12)
        }
    }

    // Advanced Toggles
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Ignore TLS Errors"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(11)
            color: configPanel.dim
            Layout.fillWidth: true
        }
        Switch { id: tlsSwitch; checked: configPanel.ignoreTls }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "OpenSSL Fix (Legacy)"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(11)
            color: configPanel.dim
            Layout.fillWidth: true
        }
        Switch { id: opensslSwitch; checked: configPanel.fixOpenssl }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Disable DTLS"
            font.family: configPanel.fontFamily
            font.pixelSize: Style.fontSize(11)
            color: configPanel.dim
            Layout.fillWidth: true
        }
        Switch { id: dtlsSwitch; checked: configPanel.noDtls }
    }

    // Save Button
    Button {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)
        text: "Save & Apply"
        onClicked: configPanel.saveConfig()
    }
}
