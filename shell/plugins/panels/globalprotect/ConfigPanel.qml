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

    // Form properties
    property string portal: ""
    property string gateway: ""
    property bool isSaml: true
    property string username: ""
    property string password: ""
    property string totp: ""
    property bool headless: true
    property string browser: "default"
    property bool ignoreTls: false
    property bool fixOpenssl: false
    property bool noDtls: false

    spacing: Style.space(10)

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
                    configPanel.totp = data.totp || ""
                    configPanel.headless = (data.headless !== undefined) ? data.headless : true
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
            configPanel.isSaml ? "true" : "false",
            totpInput.text.trim(),
            configPanel.headless ? "true" : "false",
            browserInput.text.trim(),
            configPanel.ignoreTls ? "true" : "false",
            configPanel.fixOpenssl ? "true" : "false",
            configPanel.noDtls ? "true" : "false"
        ]
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
        saveProc.running = true
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Style.space(2)

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "GlobalProtect Settings"
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
            text: "VPN Portal"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: portalInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.portal
            placeholderText: "vpn.bps.go.id"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
        }
    }

    // Gateway
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Gateway (optional)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: gwInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.gateway
            placeholderText: "Leave blank to match portal"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
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
            text: "Username (without @bps.go.id)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: userInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.username
            placeholderText: "setia.pambudi"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
        }
    }

    // Password
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Password"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: passInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.password
            password: true
            placeholderText: "••••••••"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
        }
    }

    // SAML toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Use SAML / SSO Login"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
        }

        Ui.ToggleSwitch {
            id: samlSwitch
            checked: configPanel.isSaml
            foreground: configPanel.foreground
            onToggled: configPanel.isSaml = !configPanel.isSaml
        }
    }

    // TOTP secret
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        visible: configPanel.isSaml

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "TOTP Secret (Base32 or otpauth:// URI)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: totpInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.totp
            password: true
            placeholderText: "JBSWY3DPEHPK3PXP"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
        }
    }

    // Headless toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        visible: configPanel.isSaml

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Automatic TOTP (no browser)"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
        }

        Ui.ToggleSwitch {
            id: headlessSwitch
            checked: configPanel.headless
            foreground: configPanel.foreground
            onToggled: configPanel.headless = !configPanel.headless
        }
    }

    // Browser fallback
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        visible: configPanel.isSaml && (!configPanel.headless || totpInput.text.trim() === "")

        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "SAML Browser (brave, firefox, chromium, default)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }

        Ui.TextField {
            id: browserInput
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: configPanel.browser
            placeholderText: "default"
            color: configPanel.foreground
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.body
            foreground: configPanel.foreground
        }
    }

    // Security note
    Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        wrapMode: Text.WordWrap
        text: "Password and TOTP are stored locally in ~/.config/globalprotect/config (mode 600)."
        color: configPanel.dim
        font.family: configPanel.fontFamily
        font.pixelSize: Style.font.bodySmall
    }

    // Advanced toggles
    RowLayout {
        Layout.fillWidth: true
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Ignore TLS Errors"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.ToggleSwitch {
            checked: configPanel.ignoreTls
            foreground: configPanel.foreground
            onToggled: configPanel.ignoreTls = !configPanel.ignoreTls
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "OpenSSL Fix (Legacy)"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.ToggleSwitch {
            checked: configPanel.fixOpenssl
            foreground: configPanel.foreground
            onToggled: configPanel.fixOpenssl = !configPanel.fixOpenssl
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: "Disable DTLS"
            color: configPanel.dim
            font.family: configPanel.fontFamily
            font.pixelSize: Style.font.bodySmall
        }
        Ui.ToggleSwitch {
            checked: configPanel.noDtls
            foreground: configPanel.foreground
            onToggled: configPanel.noDtls = !configPanel.noDtls
        }
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)
        spacing: Style.space(8)

        Ui.Button {
            text: "Cancel"
            Layout.fillWidth: true
            fontFamily: configPanel.fontFamily
            fontSize: Style.font.body
            foreground: configPanel.foreground
            focusable: true
            bordered: true
            onClicked: configPanel.closeRequested()
        }

        Ui.Button {
            text: "Save & Apply"
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
