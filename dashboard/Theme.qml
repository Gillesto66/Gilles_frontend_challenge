pragma Singleton
import QtQuick

// =============================================================================
// Theme.qml
// -----------------------------------------------------------------------------
// Jetons de design centralises, extraits de maquette/DESIGN.md ("Lumina
// Transit"). Purement visuel : aucune donnee vehicule ici. Singleton QML afin
// que tous les composants de rendu (Main.qml, SpeedometerGauge.qml,
// ThrottleGauge.qml) partagent la meme palette sans la dupliquer.
// =============================================================================
QtObject {
    readonly property color background: "#000000"
    readonly property color surface: "#121317"
    readonly property color surfaceContainerLowest: "#0d0e12"
    readonly property color surfaceContainerLow: "#1a1b1f"
    readonly property color surfaceContainer: "#1e1f23"
    readonly property color surfaceContainerHigh: "#292a2e"
    readonly property color surfaceContainerHighest: "#343539"

    readonly property color onSurface: "#e3e2e7"
    readonly property color onSurfaceVariant: "#b9cacb"
    readonly property color outlineVariant: "#3b494b"

    // Cyan electrique : donnees actives / etats "Go"
    readonly property color primary: "#00f0ff"
    readonly property color onPrimary: "#00363a"

    // Orange securite : reserve aux alertes et seuils critiques
    readonly property color secondary: "#ff5e07"

    // ---- Polices --------------------------------------------------------
    // "Inter" / "JetBrains Mono" sont la police d'intention de la maquette
    // (maquette/DESIGN.md), a installer sur l'image Raspberry Pi pour un
    // rendu fidele. Ce ne sont PAS des paquets Debian/Raspberry Pi OS
    // standard : la maquette HTML de reference les charge depuis Google
    // Fonts en ligne (maquette/code.html), ce qui n'existe pas pour une
    // application embarquee hors-ligne. Sans repli explicite, Qt
    // substituerait silencieusement une police par defaut du systeme si
    // "Inter"/"JetBrains Mono" sont absentes de l'image cible -- ce qui
    // casserait en particulier l'alignement tabulaire des chiffres
    // (vitesse, odometre, PWR : tous mis a jour en temps reel) attendu de
    // la police mono. D'ou des piles de repli explicites, a consommer via
    // "font.families" (liste) et non "font.family" (chaine unique) dans
    // tous les composants de rendu -- dernier repli generique
    // ("sans-serif" / "monospace") toujours resolu par Qt quelle que soit
    // la distribution Linux utilisee.
    readonly property string fontUi: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property var fontUiStack: [fontUi, "Noto Sans", "DejaVu Sans", "sans-serif"]
    readonly property var fontMonoStack: [fontMono, "Noto Sans Mono", "DejaVu Sans Mono", "monospace"]
}
