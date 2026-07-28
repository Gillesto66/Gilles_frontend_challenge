import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "Translations.js" as I18n

// =============================================================================
// Main.qml
// -----------------------------------------------------------------------------
// REGLE DE DECOUPLAGE (le point important) : ce fichier ne contient AUCUN
// calcul physique, AUCUNE notion de "simulation". Il connait uniquement
// l'interface exposee par VehicleDataSimulator.qml (throttlePercent /
// speedKmh / odometerKm). Le jour ou VehicleDataSimulator.qml est remplace
// par un vrai lecteur de bus CAN exposant la meme interface, ce fichier
// n'a besoin d'AUCUNE modification.
//
// Style visuel : design system "Lumina Transit" (cf. maquette/DESIGN.md),
// jetons centralises dans Theme.qml. SpeedometerGauge et ThrottleGauge sont
// de purs composants de rendu : ils recoivent des nombres et les affichent,
// sans jamais connaitre l'origine (simulee aujourd'hui, CAN demain) de ces
// nombres.
//
// Choix assume : contrairement a la maquette de reference, aucune donnee
// non couverte par le contrat de VehicleDataSimulator (batterie, 4G, vitesse
// enclenchee, temperature cabine, prochain arret...) n'est affichee ici --
// afficher des valeurs fictives aurait ete trompeur pour une evaluation
// technique. Seuls l'horloge et la date (systeme, reelles) completent le
// bandeau du bas.
// =============================================================================
Window {
    id: window

    // Resolution cible : ecran 10" du Raspberry Pi 4, 1280x800.
    width: 1280
    height: 800
    visible: true
    color: Theme.background
    title: tr.windowTitle

    // ---- Langue courante : bascule simple par etat (pas de Qt Linguist) --
    property string currentLang: "fr"
    readonly property var tr: I18n.get(currentLang)

    // ---- Horloge systeme (reelle, affichee en bas -- cf. maquette) --------
    property string _clockText: Qt.formatDateTime(new Date(), "hh:mm")
    property string _dateText: Qt.formatDateTime(new Date(), "d MMM").toUpperCase()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            window._clockText = Qt.formatDateTime(new Date(), "hh:mm");
            window._dateText = Qt.formatDateTime(new Date(), "d MMM").toUpperCase();
        }
    }

    function _formatOdometer(km) {
        var clamped = Math.max(0, km);
        return clamped.toFixed(3).padStart(7, "0");
    }

    // ---- Backend (mock) -----------------------------------------------
    // Seule ligne du fichier qui "sait" que les donnees sont simulees.
    VehicleDataSimulator {
        id: vehicleData
    }

    // ---- Bandeau superieur : identite + statut systeme + langue -----------
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 32
        spacing: 16

        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: Theme.surfaceContainer
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "S1"
                color: Theme.primary
                font.families: Theme.fontUiStack
                font.pixelSize: 16
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: window.tr.brandTitle
                color: Theme.onSurface
                font.families: Theme.fontUiStack
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            Text {
                text: window.tr.brandSubtitle
                color: Theme.primary
                font.families: Theme.fontUiStack
                font.pixelSize: 12
                font.weight: Font.Bold
                font.letterSpacing: 1
            }
        }
    }

    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 32
        spacing: 12

        Rectangle {
            width: sysRow.width + 24
            height: 36
            radius: 8
            color: Theme.surfaceContainer
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1

            Row {
                id: sysRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.25; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.25; to: 1; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    text: window.tr.sysStatus
                    color: Theme.onSurfaceVariant
                    font.families: Theme.fontMonoStack
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            width: langRow.width + 24
            height: 36
            radius: 8
            color: Theme.surfaceContainer
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1

            Row {
                id: langRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "FR"
                    color: window.currentLang === "fr" ? Theme.primary : Theme.onSurfaceVariant
                    font.families: Theme.fontUiStack
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Switch {
                    checked: window.currentLang === "en"
                    anchors.verticalCenter: parent.verticalCenter
                    onToggled: window.currentLang = checked ? "en" : "fr"
                }

                Text {
                    text: "EN"
                    color: window.currentLang === "en" ? Theme.primary : Theme.onSurfaceVariant
                    font.families: Theme.fontUiStack
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ---- Centre : cadran de vitesse + odometre + jauge accelerateur -------
    Row {
        anchors.centerIn: parent
        spacing: 80

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24

            SpeedometerGauge {
                id: speedometer
                anchors.horizontalCenter: parent.horizontalCenter
                speedKmh: vehicleData.speedKmh
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: odoRow.width + 32
                height: 48
                radius: 12
                color: Theme.surfaceContainerLowest
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                Row {
                    id: odoRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: window.tr.odometerLabel
                        color: Theme.onSurfaceVariant
                        font.families: Theme.fontUiStack
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: window._formatOdometer(vehicleData.odometerKm)
                        color: Theme.primary
                        font.families: Theme.fontMonoStack
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "KM"
                        color: Theme.onSurfaceVariant
                        font.families: Theme.fontUiStack
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20

            ThrottleGauge {
                id: throttleGauge
                anchors.horizontalCenter: parent.horizontalCenter
                percent: vehicleData.throttlePercent
            }

            // ---- Entree : jauge d'accelerateur interactive (0-100 %) ------
            // Seule cette valeur remonte vers le backend ; l'UI n'a jamais
            // acces a la vitesse ou a l'odometre en ecriture. Ce controle ne
            // fait pas partie de la maquette (qui suppose une vraie pedale) :
            // c'est notre substitut de test pour ce prototype.
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: window.tr.testInputLabel
                    color: Theme.onSurfaceVariant
                    font.families: Theme.fontUiStack
                    font.pixelSize: 11
                }

                Slider {
                    id: throttleSlider
                    width: 140
                    from: 0
                    to: 100
                    value: 0
                    onValueChanged: vehicleData.throttlePercent = value
                }
            }
        }
    }

    // ---- Bandeau inferieur : horloge / date (reelles) ---------------------
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 32
        spacing: 20

        Text {
            text: window._clockText
            color: Theme.onSurface
            font.families: Theme.fontMonoStack
            font.pixelSize: 22
            font.weight: Font.Medium
        }

        Text {
            text: window._dateText
            color: Theme.onSurfaceVariant
            font.families: Theme.fontMonoStack
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
