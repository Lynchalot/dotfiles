// qmllint disable unqualified
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import SddmComponents 2.0 as SDDM

import "components/clock"
import "components/inputs"
import "components/buttons"
import "layouts"
import "effects"
import "ui"

Pane {
    id: root
    height: Screen.height
    width: Screen.width
    padding: 0

    readonly property var cfg: (typeof config !== "undefined" && config) ? config : ({})
    readonly property string formPos: String(cfg.FormPosition || "center")
    readonly property var sddmApi: (typeof sddm !== "undefined" && sddm) ? sddm : null
    readonly property color startupColor: (cfg.StartupBackgroundColor && cfg.StartupBackgroundColor !== "") ? cfg.StartupBackgroundColor : "#000000"

    readonly property color accentColor: (cfg.FocusBorderColor && cfg.FocusBorderColor !== "") ? cfg.FocusBorderColor : (cfg.HoverLoginButtonBackgroundColor || "#fdb039")
    readonly property color errorColor: (cfg.ErrorTextColor && cfg.ErrorTextColor !== "") ? cfg.ErrorTextColor : "#f2685a"
    readonly property color warningColor: (cfg.WarningTextColor && cfg.WarningTextColor !== "") ? cfg.WarningTextColor : accentColor

    readonly property real fieldWidth: {
        const w = Number(cfg.FieldWidth);
        return (!isNaN(w) && w > 0) ? w : Math.min(root.width * 0.2, root.font.pointSize * 36);
    }

    readonly property bool capsOn: (typeof keyboard !== "undefined" && keyboard) ? keyboard.capsLock : false
    property string errorText: ""

    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    palette.buttonText: cfg.HoverSystemButtonsIconsColor || "#ffffff"

    background: Rectangle {
        color: root.startupColor
    }

    font {
        family: cfg.Font || font.family
        pointSize: (cfg.FontSize !== "" && typeof cfg.FontSize !== "undefined") ? parseInt(cfg.FontSize) : (parseInt(height / 80) || 13)
        weight: Font.Medium
    }

    focus: true

    Item {
        id: fxVisual
        anchors.fill: parent

        Background {
            id: bg
            config: root.cfg
            fallbackColor: root.startupColor
        }

        BlurEffect {
            id: blurOverlay
            sourceItem: bg.imageItem
            config: root.cfg
        }

        Rectangle {
            id: formScrim
            z: 0.8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: form.width * (root.formPos === "center" ? 1.6 : 1.35)
            x: {
                if (root.formPos === "right")
                    return parent.width - width;
                if (root.formPos === "center")
                    return (parent.width - width) / 2;
                return 0;
            }

            readonly property color base: (root.cfg.FormBackgroundColor && root.cfg.FormBackgroundColor !== "") ? root.cfg.FormBackgroundColor : "#070304"
            readonly property real strength: {
                const v = Number(root.cfg.FormScrimOpacity);
                return (!isNaN(v) && v >= 0 && v <= 1) ? v : 0.72;
            }
            readonly property color scrimStrong: Qt.rgba(base.r, base.g, base.b, strength)
            readonly property color scrimMid: Qt.rgba(base.r, base.g, base.b, strength * 0.42)
            readonly property color scrimClear: Qt.rgba(base.r, base.g, base.b, 0)

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: root.formPos === "left" ? formScrim.scrimStrong : formScrim.scrimClear
                }
                GradientStop {
                    position: 0.5
                    color: root.formPos === "center" ? formScrim.scrimStrong : formScrim.scrimMid
                }
                GradientStop {
                    position: 1.0
                    color: root.formPos === "right" ? formScrim.scrimStrong : formScrim.scrimClear
                }
            }
        }

        ColumnLayout {
            id: form
            z: 1

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            y: parent.height * 0.003

            width: parent.width / 2.5

            x: {
                if (root.formPos === "left")
                    return 0;
                if (root.formPos === "right")
                    return parent.width - width;
                return (parent.width - width) / 2;
            }

            SDDM.TextConstants {
                id: textConstants
            }

            Clock {
                rootItem: root
                config: root.cfg
            }

            Item {
                Layout.preferredHeight: root.font.pointSize * 1
            }

            Column {
                id: inputContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: -1
                Layout.leftMargin: 0
                Layout.fillWidth: true
                spacing: UiTokens.spacing_xs

                UsernameInput {
                    id: usernameInput
                    nextDown: passwordInput.password
                    prevTab: environmentButton.focusTarget
                }

                PasswordField {
                    id: passwordInput
                    nextDown: loginButton.authenticateBtn
                    prevField: usernameInput.username
                    nextTab: environmentButton.focusTarget
                }

                Item {
                    id: statusSlot
                    width: parent.width
                    height: root.font.pointSize * 2

                    Text {
                        id: statusMessage
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight

                        text: root.errorText !== "" ? root.errorText : (root.capsOn ? textConstants.capslockWarning : "")
                        color: root.errorText !== "" ? root.errorColor : root.warningColor
                        opacity: text !== "" ? 1 : 0

                        font {
                            pointSize: root.font.pointSize * 0.8
                            family: root.font.family
                            weight: Font.Medium
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }

                Timer {
                    id: errorClearTimer
                    interval: 4000
                    repeat: false
                    onTriggered: root.errorText = ""
                }

                LoginButton {
                    id: loginButton
                    usernameField: usernameInput.username
                    passwordField: passwordInput.password
                    environmentIndex: environmentButton.currentIndex
                }

                Connections {
                    target: root.sddmApi

                    function onLoginSucceeded() {
                        root.errorText = "";
                        errorClearTimer.stop();
                    }

                    function onLoginFailed() {
                        root.errorText = textConstants.loginFailed;
                        errorClearTimer.restart();
                        passwordInput.indicateFailure();
                    }
                }
            }

            SystemButtonsLayout {}

            Item {
                Layout.preferredHeight: root.font.pointSize * 0.5
            }

            EnvironmentButton {
                id: environmentButton
                nextTab: usernameInput.username
                prevTab: passwordInput.password
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.forceActiveFocus()
        }
    }
}
