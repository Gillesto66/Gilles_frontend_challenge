import QtQuick

// =============================================================================
// SpeedometerGauge.qml
// -----------------------------------------------------------------------------
// Composant de rendu PUR (style "Lumina Transit", cf. maquette/DESIGN.md) :
// aucune notion de simulation, aucun calcul physique. Il ne fait que dessiner
// un anneau de progression dont la longueur depend lineairement de la
// propriete "speedKmh" recue de l'exterieur.
//
// Fluidite : "_animatedSpeed" est liee a la vitesse reelle via une simple
// binding, mais un "Behavior on _animatedSpeed" intercepte chaque changement
// et l'anime. On utilise SmoothedAnimation (et non NumberAnimation) car la
// source (vehicleData.speedKmh) est un flux qui se met a jour en continu
// (20 Hz cote backend, cf. VehicleDataSimulator.qml) : SmoothedAnimation est
// concue pour etre re-ciblee en continu, a vitesse constante vers la cible
// courante, sans a-coup -- y compris si la cible change de sens tres
// rapidement (cf. test de robustesse "spam" de l'accelerateur). Une
// NumberAnimation a easing/duree fixe est pensee pour une transition
// ponctuelle et peut produire un leger a-coup si elle est relancee en boucle
// avant la fin de sa duree. Le Canvas se repeint a chaque frame de cette
// transition (onProgressChanged: requestPaint()), jamais au rythme du
// backend.
// =============================================================================
Item {
    id: root

    property real speedKmh: 0
    property real maxSpeedKmh: 50      // vitesse critique du cahier des charges
    property real warnThresholdKmh: 46 // zone critique -> bascule couleur securite

    width: 400
    height: 400

    readonly property real _clampedSpeed: Math.max(0, Math.min(speedKmh, maxSpeedKmh))
    property real _animatedSpeed: _clampedSpeed
    Behavior on _animatedSpeed {
        SmoothedAnimation { velocity: 150 }
    }

    readonly property bool _warning: _animatedSpeed >= warnThresholdKmh

    // Anneau ouvert en bas (comme un cadran de vitesse classique), pas un
    // cercle complet : _gapDeg degres d'ouverture centres sur le bas.
    readonly property real _gapDeg: 40
    readonly property real _sweepDeg: 360 - _gapDeg
    readonly property real _startDeg: 180 + _gapDeg / 2

    // ---- Panneau neomorphique --------------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceContainer
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
    }

    // ---- Anneau de vitesse (piste + progression + halo lumineux) ----------
    Canvas {
        id: ring
        anchors.fill: parent
        anchors.margins: 24

        property real progress: root._animatedSpeed / root.maxSpeedKmh
        property bool warn: root._warning
        onProgressChanged: requestPaint()
        onWarnChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;
            var r = Math.min(width, height) / 2 - 6;
            var lineWidth = 12;

            function toRad(deg) { return (deg - 90) * Math.PI / 180; }

            // Piste de fond attenuee
            ctx.beginPath();
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.strokeStyle = Theme.surfaceContainerHigh;
            ctx.globalAlpha = 0.6;
            ctx.arc(cx, cy, r, toRad(root._startDeg), toRad(root._startDeg + root._sweepDeg));
            ctx.stroke();
            ctx.globalAlpha = 1;

            // Progression (halo + trait net). Le halo est simule par un
            // trait plus large et translucide dessous, PAS par
            // ctx.shadowBlur : le flou de shadowBlur est un effet logiciel
            // (convolution par pixel) couteux en CPU/GPU, reexecute a
            // chaque repaint -- donc a chaque frame d'animation. Meme
            // technique que le halo de ThrottleGauge (Rectangle translucide
            // derriere le remplissage), pour un cout constant et une
            // coherence visuelle entre les deux jauges.
            var sweep = root._sweepDeg * Math.max(0, Math.min(1, progress));
            if (sweep > 0.5) {
                var color = warn ? Theme.secondary : Theme.primary;
                var startRad = toRad(root._startDeg);
                var endRad = toRad(root._startDeg + sweep);

                ctx.beginPath();
                ctx.lineWidth = lineWidth + 10;
                ctx.lineCap = "round";
                ctx.strokeStyle = color;
                ctx.globalAlpha = 0.25;
                ctx.arc(cx, cy, r, startRad, endRad);
                ctx.stroke();
                ctx.globalAlpha = 1;

                ctx.beginPath();
                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.strokeStyle = color;
                ctx.arc(cx, cy, r, startRad, endRad);
                ctx.stroke();
            }
        }
    }

    // ---- Lecture numerique -------------------------------------------------
    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.speedKmh.toFixed(0)
            color: root._warning ? Theme.secondary : Theme.onSurface
            font.families: Theme.fontUiStack
            font.pixelSize: 96
            font.weight: Font.Bold
            font.letterSpacing: -2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "KM/H"
            color: Theme.onSurfaceVariant
            font.families: Theme.fontUiStack
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 2
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: maxLabel.width + 20
            height: maxLabel.height + 8
            radius: height / 2
            color: Theme.surfaceContainerHigh
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Text {
                id: maxLabel
                anchors.centerIn: parent
                text: "MAX " + root.maxSpeedKmh.toFixed(0)
                color: Theme.primary
                font.families: Theme.fontMonoStack
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }
}
