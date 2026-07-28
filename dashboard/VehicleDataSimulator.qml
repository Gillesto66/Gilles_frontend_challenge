import QtQuick

// =============================================================================
// VehicleDataSimulator.qml
// -----------------------------------------------------------------------------
// C'EST le "composant dedie" impose par la regle d'architecture : le seul
// endroit de tout le projet qui sait que les donnees sont simulees.
//
// Contrat de donnees expose (= ce qu'un vrai flux CAN devrait fournir) :
//   - throttlePercent (IN)  : 0-100, ecrit par l'UI (pedale/jauge)
//   - speedKmh        (OUT) : vitesse courante en km/h
//   - odometerKm      (OUT) : distance cumulee en km
//
// Point de bascule vers le reel : le jour ou le bus CAN du vehicule est
// disponible, ce fichier est remplace par ex. par "VehicleCanBusReader.qml"
// qui ouvre un socket SocketCAN (AF_CAN), decode les trames du VCU/pedale et
// assigne les memes trois proprietes. Main.qml continue de binder sur
// "vehicleData.speedKmh" / "vehicleData.odometerKm" / "vehicleData.throttlePercent"
// sans AUCUNE modification : il ignore totalement l'existence de ce fichier,
// il ne connait que son interface (les proprietes ci-dessous).
//
// Toute la physique (inertie, freinage roue libre) est deleguee au module JS
// pur SimulationEngine.js : ce fichier ne fait que "cabler" une horloge
// (Timer) sur ce module et republier son etat sous forme de proprietes QML
// bindables.
// =============================================================================
import "SimulationEngine.js" as Sim

QtObject {
    id: root

    // ---- Entree : position de la pedale (0-100 %) --------------------------
    property real throttlePercent: 0
    onThrottlePercentChanged: Sim.setThrottle(throttlePercent)

    // ---- Sorties : a considerer en lecture seule depuis l'exterieur --------
    property real speedKmh: 0
    property real odometerKm: 0

    // Horodatage du dernier tick, pour integrer sur un pas de temps reel
    // (dt mesure) plutot que sur l'intervalle nominal du Timer : plus
    // robuste face aux micro-gigues d'ordonnancement d'un Raspberry Pi 4.
    property real _lastTimestampMs: 0

    property Timer _clock: Timer {
        interval: 50 // 20 Hz : assez fluide pour un cadran, leger pour le RPi4
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            var now = Date.now();
            var dt = root._lastTimestampMs === 0 ? 0 : (now - root._lastTimestampMs) / 1000;
            root._lastTimestampMs = now;

            Sim.update(dt);
            root.speedKmh = Sim.speedKmh();
            root.odometerKm = Sim.odometerKm();
        }
    }
}
