// qmllint disable unqualified

import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0 as SDDM

Rectangle {
    id: userInputContainer
    implicitHeight: root.font.pointSize * 4.5
    implicitWidth: root.fieldWidth
    anchors.horizontalCenter: parent.horizontalCenter
    color: "transparent"

    property alias username: userInput
    property Item nextDown
    property Item prevTab
    signal accepted(string username)

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

    function selectUser(index) {
        userPicker.currentIndex = index;
        userInput.text = userPicker.currentText;
        userMenu.close();
        if (userInputContainer.nextDown)
            userInputContainer.nextDown.forceActiveFocus();
    }

    SDDM.TextConstants {
        id: loginConstants
    }

    Rectangle {
        id: inputFrame
        anchors.centerIn: parent
        width: parent.width
        height: root.font.pointSize * 3
        radius: 24
        color: Qt.rgba(parseInt(config.LoginFieldBackgroundColor.slice(1, 3), 16) / 255, parseInt(config.LoginFieldBackgroundColor.slice(3, 5), 16) / 255, parseInt(config.LoginFieldBackgroundColor.slice(5, 7), 16) / 255, 0.25)
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
            id: userInput
            anchors.centerIn: parent
            width: parent.width - root.font.pointSize * 5
            height: parent.height
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            z: 1

            text: userPicker.currentText

            font {
                bold: true
                pointSize: root.font.pointSize
                family: root.font.family
                capitalization: config.AllowUppercaseLettersInUsernames == "false" ? Font.AllLowercase : Font.MixedCase
            }
            color: config.LoginFieldTextColor
            selectByMouse: true
            renderType: Text.QtRendering
            onFocusChanged: if (focus)
                selectAll()
            onAccepted: userInputContainer.accepted(userInput.text)

            KeyNavigation.down: userInputContainer.nextDown
            KeyNavigation.tab: userInputContainer.nextDown
            KeyNavigation.backtab: userInputContainer.prevTab ? userInputContainer.prevTab : userInputContainer.nextDown

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_F4 || (event.key === Qt.Key_Down && (event.modifiers & Qt.AltModifier)) || (event.key === Qt.Key_Up && (event.modifiers & Qt.AltModifier))) {
                    userMenu.visible ? userMenu.close() : userMenu.open();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape && userMenu.visible) {
                    userMenu.close();
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && !(event.modifiers & Qt.AltModifier) && userPicker.count > 1) {
                    // keyboard: Up/Down step through the users (only when there is more than one;
                    // otherwise Down keeps moving to the password field)
                    var step = event.key === Qt.Key_Down ? 1 : -1;
                    userPicker.currentIndex = (userPicker.currentIndex + step + userPicker.count) % userPicker.count;
                    userInput.text = userPicker.currentText;
                    userInput.selectAll();
                    event.accepted = true;
                }
            }

            Rectangle {
                id: userPlaceholder
                anchors.fill: parent
                color: "transparent"
                visible: userInput.text === ""

                Text {
                    anchors.centerIn: parent
                    text: loginConstants.userName
                    color: config.PlaceholderTextColor
                    font: userInput.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            id: chevronArea
            z: 5
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.font.pointSize * 3.5

            MouseArea {
                id: chevronTrigger
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    userInput.forceActiveFocus();
                    userMenu.visible ? userMenu.close() : userMenu.open();
                }
            }

            Canvas {
                id: chevron
                width: root.font.pointSize * 1.2
                height: width
                anchors.centerIn: parent

                readonly property color strokeColor: (chevronTrigger.containsMouse || userMenu.visible) ? config.HoverLoginButtonBackgroundColor : config.PlaceholderTextColor

                rotation: userMenu.visible ? 180 : 0
                onStrokeColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = chevron.strokeColor;
                    ctx.lineWidth = Math.max(1.5, width * 0.14);
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(width * 0.22, height * 0.38);
                    ctx.lineTo(width * 0.5, height * 0.66);
                    ctx.lineTo(width * 0.78, height * 0.38);
                    ctx.stroke();
                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: userInputContainer.animationDuration
                        easing.type: userInputContainer.animationEasing
                    }
                }
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: userInputContainer.animationDuration
                easing.type: userInputContainer.animationEasing
            }
        }

        states: [
            State {
                name: "userInputFocused"
                when: userInput.activeFocus
                PropertyChanges {
                    inputFrame.border.width: 1
                }
                PropertyChanges {
                    inputFrame.border.color: root.accentColor
                }
                PropertyChanges {
                    userInput.color: config.LoginFieldTextColor
                }
            }
        ]
    }

    ComboBox {
        id: userPicker
        visible: false
        model: userModel
        currentIndex: model.lastIndex
        textRole: "name"
        onActivated: userInput.text = currentText

        popup: Popup {
            id: userMenu
            width: userInputContainer.width
            y: (userInputContainer.height + inputFrame.height) / 2 + 6
            x: 0
            padding: 10
            implicitHeight: userListContent.implicitHeight + 20
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                radius: 12
                color: config.DropdownBackgroundColor
                border.width: 1
                border.color: config.DropdownBorderColor
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12
                    samples: 24
                    color: Qt.rgba(0, 0, 0, 0.3)
                }
            }

            contentItem: ListView {
                id: userListContent
                implicitHeight: Math.min(contentHeight, root.height * 0.35)
                clip: true
                model: userPicker.popup.visible ? userPicker.delegateModel : null
                currentIndex: userPicker.currentIndex

                delegate: Rectangle {
                    id: userDelegate
                    readonly property bool isCurrent: userListContent.currentIndex === index

                    width: userListContent.width
                    height: delegateUserText.implicitHeight + 16
                    color: userDelegate.isCurrent ? config.DropdownSelectedBackgroundColor : (userDelegateArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                    radius: 8
                    border.width: userDelegate.isCurrent ? 1 : 0
                    border.color: config.DropdownSelectedBorderColor

                    Text {
                        id: delegateUserText
                        anchors.centerIn: parent
                        text: name
                        font {
                            pointSize: root.font.pointSize * 0.9
                            capitalization: config.AllowUppercaseLettersInUsernames == "false" ? Font.AllLowercase : Font.MixedCase
                            family: root.font.family
                            weight: Font.Medium
                        }
                        color: userDelegate.isCurrent ? config.DropdownSelectedTextColor : config.DropdownTextColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        id: userDelegateArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: userInputContainer.selectUser(index)
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }

            enter: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 80
                }
            }

            exit: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 80
                }
            }
        }
    }
}
