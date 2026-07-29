pragma ComponentBehavior: Bound
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
// jetons centralises dans Theme.qml. SpeedometerGauge, ThrottleGauge,
// NavSidebar et Placeholder sont de purs composants de rendu : ils recoivent
// des valeurs (nombres, cle active, texte) et les affichent, sans jamais
// connaitre l'origine (simulee aujourd'hui, CAN demain) de ces nombres.
//
// Choix assume : contrairement a la maquette de reference, aucune donnee
// non couverte par le contrat de VehicleDataSimulator (batterie, 4G, vitesse
// enclenchee, temperature cabine, prochain arret...) n'est affichee ici --
// afficher des valeurs fictives aurait ete trompeur pour une evaluation
// technique. Seuls l'horloge et la date (systeme, reelles) completent le
// bandeau du bas. Meme logique pour la sidebar, via le Loader plus bas :
// seul "Dashboard" charge un contenu reel, les autres entrees (Route,
// Climatisation, Info passagers, Diagnostics) chargent Placeholder.qml --
// ce ne sont pas des modules implementes, et ce deliberement (voir README,
// section "Scalabilite et Navigation").
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

    // ---- Section active de la sidebar. Seule "dashboard" a un contenu reel.
    property string activeNav: "dashboard"

    readonly property var navItems: [
        { key: "dashboard", icon: "▦", label: tr.navDashboard },
        { key: "route", icon: "→", label: tr.navRoute },
        { key: "climate", icon: "❄", label: tr.navClimate },
        { key: "passenger", icon: "◎", label: tr.navPassenger },
        { key: "diagnostics", icon: "⚙", label: tr.navDiagnostics }
    ]

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

    // ---- Sidebar de navigation ---------------------------------------------
    NavSidebar {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        brandTitle: window.tr.brandTitle
        brandSubtitle: window.tr.brandSubtitle
        activeKey: window.activeNav
        items: window.navItems

        onItemSelected: (key) => window.activeNav = key
    }

    // ---- Zone de contenu principal ------------------------------------------
    Item {
        id: content
        anchors.left: sidebar.right
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ---- Bandeau superieur : statut systeme + langue -------------------
        Row {
            anchors.top: parent.top
            anchors.left: parent.left
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
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 32
            spacing: 12

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
                        font.family: Theme.fontUi
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
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // ---- Corps de la vue : Dashboard (reel) ou placeholder (autres) ----
        Loader {
            anchors.fill: parent
            sourceComponent: window.activeNav === "dashboard" ? dashboardView : placeholderView
        }

        // ---- Bandeau inferieur : horloge / date (reelles), persistant ------
        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 32
            spacing: 20

            Text {
                text: window._clockText
                color: Theme.onSurfaceColor
                font.family: Theme.fontMono
                font.pixelSize: 22
                font.weight: Font.Medium
            }

            Text {
                text: window._dateText
                color: Theme.onSurfaceVariant
                font.family: Theme.fontMono
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---- Vue "Dashboard" : cadran de vitesse + odometre + PWR ----------
        Component {
            id: dashboardView

            Item {
                // Le Loader ne redimensionne pas automatiquement l'item charge
                // quand sa propre taille est deja fixee (ici via anchors.fill
                // sur le Loader) : sans ce anchors.fill, "anchors.centerIn:
                // parent" plus bas se recalerait sur un item de taille 0x0.
                anchors.fill: parent

                // ---- Cadran + odometre : centres dans la zone dashboard --------
                Column {
                    anchors.centerIn: parent
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
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: window._formatOdometer(vehicleData.odometerKm)
                                color: Theme.primary
                                font.family: Theme.fontMono
                                font.pixelSize: 20
                                font.weight: Font.Medium
                                font.letterSpacing: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "KM"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ---- PWR : plaquee sur le bord droit, comme sur la maquette ----
                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 48
                    spacing: 20

                    ThrottleGauge {
                        id: throttleGauge
                        anchors.horizontalCenter: parent.horizontalCenter
                        percent: vehicleData.throttlePercent
                    }

                    // ---- Entree : jauge d'accelerateur interactive (0-100 %) --
                    // Seule cette valeur remonte vers le backend ; l'UI n'a
                    // jamais acces a la vitesse ou a l'odometre en ecriture.
                    // Ce controle ne fait pas partie de la maquette (qui
                    // suppose une vraie pedale) : c'est notre substitut de
                    // test pour ce prototype.
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: window.tr.testInputLabel
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontUi
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
        }

        // ---- Vues non implementees : espace reserve, pas de fausses donnees -
        // Placeholder.qml est un composant de rendu pur au meme titre que
        // SpeedometerGauge/ThrottleGauge/NavSidebar : il ne recoit qu'un
        // texte, jamais de donnee vehicule. C'est le point d'ancrage ou
        // brancher un futur composant reel (ex. ClimateView.qml) sans toucher
        // ni a la sidebar ni au Loader ci-dessus.
        Component {
            id: placeholderView

            Placeholder {
                anchors.fill: parent
                message: window.tr.placeholderModule
            }
        }
    }
}
