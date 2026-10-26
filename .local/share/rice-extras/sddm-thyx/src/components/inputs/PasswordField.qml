// qmllint disable unqualified

import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0 as SDDM

Rectangle {
    id: secureInputContainer
    implicitHeight: root.font.pointSize * 4.5
    implicitWidth: root.fieldWidth
    anchors.horizontalCenter: parent.horizontalCenter
    color: "transparent"

    function indicateFailure() {
        secureInput.text = "";
        secureInputContainer.revealed = false;
        shakeAnimation.restart();
        secureInput.forceActiveFocus();
    }

    property alias password: secureInput
    property Item nextDown
    property Item prevField
    property Item nextTab
    property bool revealed: false
    signal accepted(string password)

    readonly property int animationDuration: Number(config.AnimationDuration || 80)
    readonly property int animationEasing: {
        switch (config.AnimationEasing) {
        case "OutCubic":
            return Easing.OutCubic;
        case "OutBack":
            return Easing.OutBack;
        case "OutQuart":
        default:
            return Easing.OutQuart;
        }
    }

    SDDM.TextConstants {
        id: authConstants
    }

    SequentialAnimation {
        id: shakeAnimation
        loops: 2

        NumberAnimation {
            target: inputWrapper
            property: "anchors.horizontalCenterOffset"
            to: -9
            duration: 45
            easing.type: Easing.OutSine
        }
        NumberAnimation {
            target: inputWrapper
            property: "anchors.horizontalCenterOffset"
            to: 9
            duration: 45
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: inputWrapper
            property: "anchors.horizontalCenterOffset"
            to: 0
            duration: 45
            easing.type: Easing.InSine
        }
    }

    Rectangle {
        id: inputWrapper
        anchors.centerIn: parent
        width: parent.width
        height: root.font.pointSize * 3
        radius: 24
        color: Qt.rgba(parseInt(config.PasswordFieldBackgroundColor.slice(1, 3), 16) / 255, parseInt(config.PasswordFieldBackgroundColor.slice(3, 5), 16) / 255, parseInt(config.PasswordFieldBackgroundColor.slice(5, 7), 16) / 255, 0.25)
        border.width: 0
        border.color: "transparent"

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8
            samples: 16
            color: Qt.rgba(0, 0, 0, 0.15)
        }

        TextInput {
            id: secureInput
            anchors.centerIn: parent
            width: parent.width - root.font.pointSize * 5
            height: parent.height
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter

            font {
                pointSize: root.font.pointSize
                family: root.font.family
                weight: Font.Bold
            }
            color: config.PasswordFieldTextColor
            focus: true
            selectByMouse: true
            renderType: Text.QtRendering

            echoMode: secureInputContainer.revealed ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: undefined

            onTextChanged: if (text === "")
                secureInputContainer.revealed = false

            onAccepted: secureInputContainer.accepted(secureInput.text)
            KeyNavigation.down: secureInputContainer.nextDown
            KeyNavigation.up: secureInputContainer.prevField
            KeyNavigation.tab: secureInputContainer.nextTab ? secureInputContainer.nextTab : secureInputContainer.prevField
            KeyNavigation.backtab: secureInputContainer.prevField

            Rectangle {
                id: placeholder
                anchors.fill: parent
                color: "transparent"
                visible: secureInput.text === ""

                Text {
                    anchors.centerIn: parent
                    text: authConstants.password
                    color: config.PlaceholderTextColor
                    font: secureInput.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            id: revealArea
            z: 5
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.font.pointSize * 3.5
            opacity: secureInput.text.length > 0 ? 1 : 0
            visible: opacity > 0

            MouseArea {
                id: revealTrigger
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    secureInputContainer.revealed = !secureInputContainer.revealed;
                    secureInput.forceActiveFocus();
                }
            }

            Canvas {
                id: eyeIcon
                width: root.font.pointSize * 1.5
                height: width
                anchors.centerIn: parent

                readonly property color strokeColor: (revealTrigger.containsMouse || secureInputContainer.revealed) ? config.HoverLoginButtonBackgroundColor : config.PlaceholderTextColor
                readonly property bool slashed: secureInputContainer.revealed

                onStrokeColorChanged: requestPaint()
                onSlashedChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    const w = width;
                    const h = height;
                    ctx.reset();
                    ctx.strokeStyle = eyeIcon.strokeColor;
                    ctx.lineWidth = Math.max(1.4, w * 0.1);
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    ctx.beginPath();
                    ctx.moveTo(w * 0.06, h * 0.5);
                    ctx.bezierCurveTo(w * 0.28, h * 0.16, w * 0.72, h * 0.16, w * 0.94, h * 0.5);
                    ctx.bezierCurveTo(w * 0.72, h * 0.84, w * 0.28, h * 0.84, w * 0.06, h * 0.5);
                    ctx.closePath();
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.arc(w * 0.5, h * 0.5, w * 0.15, 0, Math.PI * 2);
                    ctx.stroke();

                    if (eyeIcon.slashed) {
                        ctx.beginPath();
                        ctx.moveTo(w * 0.16, h * 0.84);
                        ctx.lineTo(w * 0.84, h * 0.16);
                        ctx.stroke();
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: secureInputContainer.animationDuration
                        easing.type: secureInputContainer.animationEasing
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: secureInputContainer.animationDuration
                    easing.type: secureInputContainer.animationEasing
                }
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: config.AnimationDuration || 80
                easing.type: {
                    switch (config.AnimationEasing) {
                    case "OutCubic":
                        return Easing.OutCubic;
                    case "OutBack":
                        return Easing.OutBack;
                    case "OutQuart":
                    default:
                        return Easing.OutQuart;
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: config.AnimationDuration || 80
                easing.type: {
                    switch (config.AnimationEasing) {
                    case "OutCubic":
                        return Easing.OutCubic;
                    case "OutBack":
                        return Easing.OutBack;
                    case "OutQuart":
                    default:
                        return Easing.OutQuart;
                    }
                }
            }
        }

        states: [
            State {
                name: "inputFocused"
                when: secureInput.activeFocus
                PropertyChanges {
                    inputWrapper.border.width: 1
                }
                PropertyChanges {
                    inputWrapper.border.color: root.accentColor
                }
                PropertyChanges {
                    secureInput.color: config.PasswordFieldTextColor
                }
            }
        ]
    }
}
