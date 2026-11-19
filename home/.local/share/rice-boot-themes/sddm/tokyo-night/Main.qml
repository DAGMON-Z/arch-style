// Tokyo Night login screen for SDDM
import QtQuick

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1a1b26"

    // All sizes are written for a 720-unit-high screen and scaled from there
    readonly property real u: height / 720
    readonly property string fontName: "JetBrainsMono Nerd Font"

    property var users: []
    property var sessions: []
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""
    property bool busy: false

    readonly property var currentUser: users.length > userIndex ? users[userIndex] : null
    readonly property string currentSession: sessions.length > sessionIndex ? sessions[sessionIndex] : ""

    function login() {
        if (!currentUser || busy)
            return
        message = ""
        busy = true
        sddm.login(currentUser.name, password.text, sessionIndex)
    }

    function layoutName() {
        if (typeof keyboard === "undefined" || !keyboard.layouts || keyboard.layouts.length === 0)
            return ""
        const layout = keyboard.layouts[keyboard.currentLayout]
        return layout ? layout.shortName : ""
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.message = "Wrong password"
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.message = ""
        }
    }

    // These read the user and session lists that SDDM provides
    Repeater {
        model: userModel
        Item {
            Component.onCompleted: root.users = root.users.concat([{
                name: model.name,
                label: model.realName ? model.realName : model.name
            }])
        }
    }
    Repeater {
        model: sessionModel
        Item {
            Component.onCompleted: root.sessions = root.sessions.concat([model.name])
        }
    }

    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        anchors.fill: parent
        color: "#1a1b26"
        opacity: 0.62
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            clock.text = Qt.formatTime(now, "hh:mm AP")
            date.text = Qt.formatDate(now, "dddd, d MMMM")
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20 * root.u
        spacing: 10 * root.u

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#c0caf5"
            font.family: root.fontName
            font.weight: Font.ExtraBold
            font.pixelSize: 88 * root.u
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#7aa2f7"
            font.family: root.fontName
            font.pixelSize: 20 * root.u
        }

        Item { width: 1; height: 26 * root.u }

        // User name. Click to switch if there is more than one user.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentUser ? root.currentUser.label : ""
            color: "#c0caf5"
            font.family: root.fontName
            font.pixelSize: 18 * root.u
            font.bold: true
            MouseArea {
                anchors.fill: parent
                enabled: root.users.length > 1
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320 * root.u
            height: 46 * root.u
            radius: 14 * root.u
            color: "#e616161e"
            border.width: Math.max(2, 2 * root.u)
            border.color: root.message ? "#f7768e" : (root.busy ? "#e0af68" : "#7aa2f7")

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: "#565f89"
                font.family: root.fontName
                font.pixelSize: 15 * root.u
            }
            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 42 * root.u
                anchors.rightMargin: 16 * root.u
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                focus: true
                enabled: !root.busy
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: "#c0caf5"
                selectionColor: "#283457"
                font.family: root.fontName
                font.pixelSize: 16 * root.u
                onTextEdited: root.message = ""
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
                Component.onCompleted: forceActiveFocus()
            }
            Text {
                anchors.left: password.left
                anchors.verticalCenter: parent.verticalCenter
                visible: password.text.length === 0
                text: "Password"
                color: "#565f89"
                font.family: root.fontName
                font.pixelSize: 15 * root.u
            }
        }

        // Error message, or a Caps Lock warning
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 20 * root.u
            text: root.message ? root.message
                : (typeof keyboard !== "undefined" && keyboard.capsLock ? "Caps Lock is on" : "")
            color: root.message ? "#f7768e" : "#ff9e64"
            font.family: root.fontName
            font.pixelSize: 13 * root.u
        }
    }

    // Bottom left: session and keyboard layout
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 22 * root.u
        spacing: 8 * root.u

        Pill {
            icon: ""
            label: root.currentSession
            accent: "#bb9af7"
            onClicked: {
                if (root.sessions.length > 0)
                    root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
            }
        }
        Pill {
            visible: root.layoutName() !== ""
            icon: ""
            label: root.layoutName()
            accent: "#ff9e64"
            onClicked: {
                if (keyboard.layouts.length > 1)
                    keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    // Bottom right: power buttons
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 22 * root.u
        spacing: 8 * root.u

        Pill {
            visible: sddm.canSuspend
            icon: ""
            accent: "#7dcfff"
            onClicked: sddm.suspend()
        }
        Pill {
            visible: sddm.canReboot
            icon: ""
            accent: "#e0af68"
            onClicked: sddm.reboot()
        }
        Pill {
            visible: sddm.canPowerOff
            icon: ""
            accent: "#f7768e"
            onClicked: sddm.powerOff()
        }
    }

    component Pill: Rectangle {
        id: pill
        property string icon: ""
        property string label: ""
        property color accent: "#7aa2f7"
        signal clicked()

        width: row.width + 24 * root.u
        height: 34 * root.u
        radius: height / 2
        color: area.containsMouse ? "#292e42" : "#e01a1b26"
        border.width: 1
        border.color: "#b3414868"

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8 * root.u
            Text {
                text: pill.icon
                color: pill.accent
                font.family: root.fontName
                font.pixelSize: 15 * root.u
            }
            Text {
                visible: pill.label !== ""
                text: pill.label
                color: "#c0caf5"
                font.family: root.fontName
                font.pixelSize: 13 * root.u
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}
